/****** Object:  StoredProcedure [dbo].[PollingEmployeeDequeue]    Script Date: 24/05/2023 15:31:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Dan Probert (Affinus)
-- Create date: 2023-05-23
-- Description:	Selects a set of EventMessage elements (as JSON) for each EmployeeMessage which match the given criteria
-- =============================================
CREATE PROCEDURE [dbo].[PollingEmployeeDequeue]
    @EventType nvarchar(255),
	@ProcessingControlStatus nvarchar(50) = NULL,	-- The value to set the ControlStatus to, for the rows that have been selected by this query
    @QueryControlStatus nvarchar(50),				-- Select any EmployeeMessages that have this ControlStatus value (use NULL to ignore this parameter)
    @QueryRole nvarchar(50) = NULL,					-- Select any Employees that have this Source value (use NULL to ignore this parameter)
	@QuerySerializeEmployees bit = 0,				-- If True, then we only return one event per unique EmployeeId value
	@BatchCount int = 50,							-- Max number of records to select at one time
	@HighWatermark int = 80					        -- If more than this number of records are in a Processing status, we wait until we have less than this
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

	-- Override the BizTalk Adapter Isolation Level
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED 

	BEGIN TRAN

	-- Check if we're over the High Watermark limit i.e. we should do no work
	IF (SELECT COUNT(*)
		FROM [dbo].[Employees] e2
		WHERE e2.[ControlStatus] = COALESCE(@ProcessingControlStatus, 'Processing')
		AND e2.[Role] = COALESCE(@QueryRole, e2.[Role])) < (@HighWatermark - @BatchCount)
	BEGIN

		-- Define temp table to store the records that we're selecting
		CREATE TABLE dbo.#TempEmployees 
		(
				[EmployeeMessageId] int NOT NULL, 
				[TrackingId] nvarchar(50) NOT NULL,  
				[ControlStatus] nvarchar(50) NOT NULL, 
				[DateTimeInserted] datetime
		) 

		-- We use a different query if we're serializing Employees
		IF (@QuerySerializeEmployees = 0)
			BEGIN
				-- Select the rows to return into a temp table
				UPDATE [dbo].[Employees]
				SET [ControlStatus] = COALESCE(@ProcessingControlStatus, 'Processing'),
				[DateTimeUpdated] = GETUTCDATE()
				OUTPUT inserted.[EmployeeMessageId], inserted.[TrackingId], deleted.[ControlStatus], deleted.[DateTimeInserted]
				INTO dbo.#TempEmployees
				FROM [dbo].[Employees] e WITH (READPAST)
					INNER JOIN 
					(
						SELECT TOP(@BatchCount)
							[EmployeeId],
							[ControlStatus],
							[Role]
						FROM [dbo].[Employees] e2
						WHERE e2.[ControlStatus] = @QueryControlStatus
						AND e2.[Role] =       COALESCE(@QueryRole, e2.[Role])
						ORDER BY e2.[DateTimeInserted] ASC
					) e1 ON e1.[EmployeeId] = e.[EmployeeId]
				WHERE e1.[ControlStatus] = @QueryControlStatus
				AND e1.[Role] =       COALESCE(@QueryRole, e1.[Role])
			END
		ELSE
			BEGIN
				-- We're serializing Employees i.e. only one row per EmployeeId, and no rows if any row (for a given EmployeeId) is in a state of Processing.
				-- Update the ControlStatus and select the rows we've updated into a temp table
				UPDATE [dbo].[Employees]
				SET [ControlStatus] = COALESCE(@ProcessingControlStatus, 'Processing'),
				[DateTimeUpdated] = GETUTCDATE()
				OUTPUT inserted.[EmployeeMessageId], inserted.[TrackingId], deleted.[ControlStatus], deleted.[DateTimeInserted]
				INTO dbo.#TempEmployees
				FROM [dbo].[Employees] e WITH (READPAST)
					INNER JOIN 
					(
						SELECT TOP(@BatchCount)
							ROW_NUMBER() OVER (
								PARTITION BY [EmployeeId] 
								ORDER BY [DateTimeInserted] ASC
							) AS OrderSequence, 
							[EmployeeId],
							[ControlStatus],
							[Role]
						FROM [dbo].[Employees] e2
						WHERE e2.[ControlStatus] = @QueryControlStatus
						AND e2.[Role] =            COALESCE(@QueryRole, e2.[Role])
						AND (e2.[EmployeeId] NOT IN (SELECT [EmployeeId] FROM [dbo].[Employees] WITH (NOLOCK) WHERE [ControlStatus] = COALESCE(@ProcessingControlStatus, 'Processing')))
						ORDER BY e2.[DateTimeInserted] ASC
					) e1 ON e1.[EmployeeId] = e.[EmployeeId]
				WHERE e1.[OrderSequence] = 1
				AND e1.[ControlStatus] =   @QueryControlStatus
				AND e1.[Role] =            COALESCE(@QueryRole, e1.[Role])
			END

		-- Check if we have any data to select
		IF ((SELECT COUNT([EmployeeId]) FROM #TempEmployees) > 0)
		BEGIN
			-- Create the JSON data
			DECLARE @JsonData nvarchar(max)
       
			SELECT @JsonData =
			(
				SELECT
					GETUTCDATE()             "header.dateTimeRequested",
					te.TrackingId            "header.trackingId",
					@EventType               "event.eventType",
					te.EmployeeMessageId     "event.eventKey"
					FROM #TempEmployees te
				FOR JSON PATH
			);
         
		END

		SELECT @JsonData AS [JsonData];

		DROP TABLE #TempEmployees
	END

	COMMIT TRAN
END

