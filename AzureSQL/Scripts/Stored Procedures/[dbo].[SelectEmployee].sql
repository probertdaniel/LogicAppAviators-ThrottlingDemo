/****** Object:  StoredProcedure [dbo].[SelectEmployee]    Script Date: 24/05/2023 15:24:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Dan Probert (Affinus)
-- Create date: 2023-05-23
-- Description:	Selects a Employee (and attributes) by EmployeeMessageId
-- =============================================
CREATE PROCEDURE [dbo].[SelectEmployee]
    @EmployeeMessageId int
AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
    SET NOCOUNT ON;

    SELECT 
		em.[EmployeeMessageId], 
        em.[EmployeeId], 
        em.[TrackingId], 
        em.[ControlStatus], 
        em.[Role], 
        em.[EmployeeMessage]
    FROM [Employees] em
    WHERE em.[EmployeeMessageId] = @EmployeeMessageId

END
