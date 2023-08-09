-- =============================================
-- Author:		Dan Probert (Affinus)
-- Create date: 2023-05-23
-- Description:Employees Table
-- =============================================
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Employees]') AND type in (N'U'))
DROP TABLE [dbo].[Employees]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Employees](
	[EmployeeMessageId] [int] IDENTITY(1,1) NOT NULL,
	[ControlStatus] [nvarchar](10) NOT NULL,
	[TrackingId] [nvarchar](36) NULL,
	[EmployeeId] [int] NULL,
	[Role] [nvarchar](50) NULL,
	[EmployeeMessage] [nvarchar](max) NULL,
	[DateTimeInserted] [datetime2](7) NOT NULL,
	[DateTimeUpdated] [datetime2](7) NULL,
 CONSTRAINT [PK_Employees] PRIMARY KEY CLUSTERED 
(
	[EmployeeMessageId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


