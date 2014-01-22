USE [Test]
GO

DROP TABLE [dbo].[Compare]
DROP TABLE [dbo].[Master]

CREATE TABLE [dbo].[Compare](
	[BatchID] [int] NULL,
	[Id] [int] NULL,
	[F1] [nchar](10) NULL,
	[F2] [nchar](10) NULL,
	[F3] [nchar](10) NULL,
	[UPD] [date] NULL,
	[INS] [date] NULL,
	[DEL] [date] NULL
) ON [PRIMARY]

GO

CREATE TABLE [dbo].[Master](
	[Id] [int] NULL,
	[F1] [nchar](10) NULL,
	[F2] [nchar](10) NULL,
	[F3] [nchar](10) NULL
) ON [PRIMARY]


