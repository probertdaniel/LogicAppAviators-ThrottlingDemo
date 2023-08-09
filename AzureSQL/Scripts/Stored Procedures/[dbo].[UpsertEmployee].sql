-- =============================================
-- Author:		Dan Probert (Affinus)
-- Create date: 2023-05-23
-- Description:	Inserts or Updates Employee table for a given Employee
-- =============================================
CREATE PROCEDURE [dbo].[UpsertEmployee]
	@EmployeeMessageId int = NULL OUT,
	@ControlStatus nvarchar(10) = 'New',
    @TrackingId nvarchar(36) = NULL,
	@EmployeeId int = 0,
	@Role nvarchar(50),
	@EmployeeMessage nvarchar(max),
    @OutputEmployeeMessageId int OUT,
    @Operation nvarchar(50) OUT,
	@DateTimeUpdated datetime2 OUT
AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
    SET NOCOUNT ON;

    BEGIN TRANSACTION

	IF @TrackingId IS NULL SET @TrackingId = convert(nvarchar(50), NEWID())

    IF @EmployeeMessageId IS NULL
        BEGIN

            INSERT INTO [dbo].[Employees]
	            (
                    [ControlStatus],
					[TrackingId], 
                    [EmployeeMessage],
					[EmployeeId], 
					[Role], 
					[DateTimeInserted]
                )
            VALUES 
                (
                    @ControlStatus, 
                    @TrackingId,
                    @EmployeeMessage,
					@EmployeeId,
					@Role,
					GETUTCDATE()
                )

            SET @OutputEmployeeMessageId = @@IDENTITY
	        SET @DateTimeUpdated = GETUTCDATE()
            SET @Operation = 'Insert'
			
        END
    ELSE
        BEGIN
            UPDATE [dbo].[Employee]
	        SET [ControlStatus] = @ControlStatus,
                [EmployeeMessage] = @EmployeeMessage,
                [EmployeeId] = @EmployeeId,
                [Role] = @Role,
                [DateTimeUpdated] = GETUTCDATE()
            WHERE [EmployeeMessageId] = @EmployeeMessageId
			
			SET @DateTimeUpdated = GETUTCDATE()
            SET @OutputEmployeeMessageId = @EmployeeMessageId
            SET @Operation = 'Update'
        END

    COMMIT TRANSACTION

END

GO

