USE [master]
GO
/****** Object:  Database [Glam]    Script Date: 18/01/2014 22:15:51 ******/
CREATE DATABASE [Glam]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Glam', FILENAME = N'c:\Program Files\Microsoft SQL Server\MSSQL11.SQLEXPRESS\MSSQL\DATA\Glam.mdf' , SIZE = 5120KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'Glam_log', FILENAME = N'c:\Program Files\Microsoft SQL Server\MSSQL11.SQLEXPRESS\MSSQL\DATA\Glam_log.ldf' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [Glam] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Glam].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [Glam] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [Glam] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [Glam] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [Glam] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [Glam] SET ARITHABORT OFF 
GO
ALTER DATABASE [Glam] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [Glam] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [Glam] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [Glam] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [Glam] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [Glam] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [Glam] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [Glam] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [Glam] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [Glam] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [Glam] SET  DISABLE_BROKER 
GO
ALTER DATABASE [Glam] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [Glam] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [Glam] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [Glam] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [Glam] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [Glam] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [Glam] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [Glam] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [Glam] SET  MULTI_USER 
GO
ALTER DATABASE [Glam] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [Glam] SET DB_CHAINING OFF 
GO
ALTER DATABASE [Glam] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [Glam] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
USE [Glam]
GO
/****** Object:  User [dandan]    Script Date: 18/01/2014 22:15:51 ******/
CREATE USER [dandan] FOR LOGIN [dandan] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  DatabaseRole [admin]    Script Date: 18/01/2014 22:15:51 ******/
CREATE ROLE [admin]
GO
ALTER ROLE [db_owner] ADD MEMBER [dandan]
GO
ALTER ROLE [db_accessadmin] ADD MEMBER [dandan]
GO
ALTER ROLE [db_securityadmin] ADD MEMBER [dandan]
GO
ALTER ROLE [db_ddladmin] ADD MEMBER [dandan]
GO
ALTER ROLE [db_backupoperator] ADD MEMBER [dandan]
GO
ALTER ROLE [db_datareader] ADD MEMBER [dandan]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [dandan]
GO
ALTER ROLE [db_denydatareader] ADD MEMBER [dandan]
GO
ALTER ROLE [db_denydatawriter] ADD MEMBER [dandan]
GO
/****** Object:  StoredProcedure [dbo].[GetOrderAndItsItems]    Script Date: 18/01/2014 22:15:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetOrderAndItsItems] (@orderID int)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

		-- return new order for processing
		SELECT * FROM [Glam].[dbo].[Orders]
		WHERE [OrderID] = @orderID

		SELECT * 
		FROM [Glam].[dbo].[OrderItems]
		INNER JOIN [Items]
		ON [OrderItems].ItemID=[Items].ItemID
		WHERE [OrderID] = @orderID

END


GO
/****** Object:  StoredProcedure [dbo].[InsertNewOrder]    Script Date: 18/01/2014 22:15:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertNewOrder]
	@ClientID int,
	@Comment nvarchar(500),
	@Discount decimal	
AS
BEGIN
	SET NOCOUNT ON;	
    
	declare @StatusID int = 1 --New
    declare @id int

	INSERT INTO Orders (ClientID, StatusID, Comment, Discount) 
	VALUES (@ClientID, @StatusID, @Comment, @Discount)
	SET @id = SCOPE_IDENTITY();

	Select @id
END

GO
/****** Object:  StoredProcedure [dbo].[InsertNewOrderItem]    Script Date: 18/01/2014 22:15:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertNewOrderItem]
	@ItemID int,
	@OrderID int,	
	@Quantity int,
	@Discount decimal
AS
BEGIN
	SET NOCOUNT ON;

   INSERT INTO OrderItems (ItemID,OrderID, Quntity, Discount) VALUES (@ItemID, @OrderID, @Quantity, @Discount)
END

GO
/****** Object:  StoredProcedure [dbo].[ProcessNextPendingOrder]    Script Date: 18/01/2014 22:15:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ProcessNextPendingOrder]	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	    -- take new order from the queue (view)
		declare @orderID int
		SELECT TOP 1 @orderID = [OrderID]      
		FROM [Glam].[dbo].[NewOrders]

		-- update status to processing so its also no longer in the new orders queue
		UPDATE [Glam].[dbo].[Orders]
		SET [StatusID]=2
		WHERE [OrderID] = @orderID

		-- return new order for processing
		SELECT * FROM [Glam].[dbo].[Orders]
		WHERE [OrderID] = @orderID

		SELECT * FROM [Glam].[dbo].[OrderItems]
		WHERE [OrderID] = @orderID

END

GO
/****** Object:  StoredProcedure [dbo].[UpdateOrderStatus]    Script Date: 18/01/2014 22:15:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateOrderStatus] 	
	@OrderID int,
	@Succeeded bit	
AS
BEGIN
	SET NOCOUNT ON;
	declare @statusID int

	if(@Succeeded=1)
		set @statusID = 3
	else
	    set @statusID = 4

    UPDATE Orders SET StatusID = @statusID WHERE OrderID = @OrderID
END

GO
/****** Object:  Table [dbo].[Applications]    Script Date: 18/01/2014 22:15:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Applications](
	[ApplicationId] [uniqueidentifier] NOT NULL,
	[ApplicationName] [nvarchar](235) NOT NULL,
	[Description] [nvarchar](256) NULL,
PRIMARY KEY CLUSTERED 
(
	[ApplicationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Clients]    Script Date: 18/01/2014 22:15:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Clients](
	[ClientID] [int] NOT NULL,
	[ClientName] [nvarchar](100) NULL,
 CONSTRAINT [PK_Clients] PRIMARY KEY CLUSTERED 
(
	[ClientID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Holidays]    Script Date: 18/01/2014 22:15:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Holidays](
	[HolidayID] [int] IDENTITY(1,1) NOT NULL,
	[HolidayName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_Holidays] PRIMARY KEY CLUSTERED 
(
	[HolidayID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Items]    Script Date: 18/01/2014 22:15:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Items](
	[ItemID] [nvarchar](50) NOT NULL,
	[ItemName] [nvarchar](100) NOT NULL,
	[ItemPrice] [decimal](18, 0) NOT NULL,
 CONSTRAINT [PK_Items] PRIMARY KEY CLUSTERED 
(
	[ItemID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ItemsHolidays]    Script Date: 18/01/2014 22:15:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ItemsHolidays](
	[HolidayID] [int] NOT NULL,
	[ItemsID] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_ItemsHolidays] PRIMARY KEY CLUSTERED 
(
	[HolidayID] ASC,
	[ItemsID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Memberships]    Script Date: 18/01/2014 22:15:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Memberships](
	[UserId] [uniqueidentifier] NOT NULL,
	[ApplicationId] [uniqueidentifier] NOT NULL,
	[Password] [nvarchar](128) NOT NULL,
	[PasswordFormat] [int] NOT NULL,
	[PasswordSalt] [nvarchar](128) NOT NULL,
	[Email] [nvarchar](256) NULL,
	[PasswordQuestion] [nvarchar](256) NULL,
	[PasswordAnswer] [nvarchar](128) NULL,
	[IsApproved] [bit] NOT NULL,
	[IsLockedOut] [bit] NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[LastLoginDate] [datetime] NOT NULL,
	[LastPasswordChangedDate] [datetime] NOT NULL,
	[LastLockoutDate] [datetime] NOT NULL,
	[FailedPasswordAttemptCount] [int] NOT NULL,
	[FailedPasswordAttemptWindowStart] [datetime] NOT NULL,
	[FailedPasswordAnswerAttemptCount] [int] NOT NULL,
	[FailedPasswordAnswerAttemptWindowsStart] [datetime] NOT NULL,
	[Comment] [nvarchar](256) NULL,
PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[OrderItems]    Script Date: 18/01/2014 22:15:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrderItems](
	[ItemID] [nvarchar](50) NOT NULL,
	[OrderID] [int] NOT NULL,
	[Quntity] [int] NOT NULL,
	[Discount] [decimal](18, 0) NULL,
 CONSTRAINT [PK_OrderItems] PRIMARY KEY CLUSTERED 
(
	[ItemID] ASC,
	[OrderID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Orders]    Script Date: 18/01/2014 22:15:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Orders](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[StatusID] [int] NOT NULL,
	[ClientID] [int] NOT NULL,
	[Comment] [text] NULL,
	[Discount] [decimal](18, 0) NULL,
	[OrderDate] [datetime] NULL,
 CONSTRAINT [PK_Orders] PRIMARY KEY CLUSTERED 
(
	[OrderID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[OrderStatus]    Script Date: 18/01/2014 22:15:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrderStatus](
	[StatusID] [int] IDENTITY(1,1) NOT NULL,
	[StatusName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_OrderStatus] PRIMARY KEY CLUSTERED 
(
	[StatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Profiles]    Script Date: 18/01/2014 22:15:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Profiles](
	[UserId] [uniqueidentifier] NOT NULL,
	[PropertyNames] [nvarchar](max) NOT NULL,
	[PropertyValueStrings] [nvarchar](max) NOT NULL,
	[PropertyValueBinary] [varbinary](max) NOT NULL,
	[LastUpdatedDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Roles]    Script Date: 18/01/2014 22:15:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Roles](
	[RoleId] [uniqueidentifier] NOT NULL,
	[ApplicationId] [uniqueidentifier] NOT NULL,
	[RoleName] [nvarchar](256) NOT NULL,
	[Description] [nvarchar](256) NULL,
PRIMARY KEY CLUSTERED 
(
	[RoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Users]    Script Date: 18/01/2014 22:15:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Users](
	[UserId] [uniqueidentifier] NOT NULL,
	[ApplicationId] [uniqueidentifier] NOT NULL,
	[UserName] [nvarchar](50) NOT NULL,
	[IsAnonymous] [bit] NOT NULL,
	[LastActivityDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UsersInRoles]    Script Date: 18/01/2014 22:15:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UsersInRoles](
	[UserId] [uniqueidentifier] NOT NULL,
	[RoleId] [uniqueidentifier] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[UserId] ASC,
	[RoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  View [dbo].[AllOrders]    Script Date: 18/01/2014 22:15:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[AllOrders]
AS
SELECT        dbo.Orders.OrderID, dbo.Orders.StatusID, dbo.Orders.ClientID, dbo.Orders.Comment, dbo.Orders.Discount, dbo.Clients.ClientName, 
                         dbo.OrderStatus.StatusName
FROM            dbo.Clients INNER JOIN
                         dbo.Orders ON dbo.Clients.ClientID = dbo.Orders.ClientID INNER JOIN
                         dbo.OrderStatus ON dbo.Orders.StatusID = dbo.OrderStatus.StatusID

GO
/****** Object:  View [dbo].[NewOrders]    Script Date: 18/01/2014 22:15:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[NewOrders]
AS
SELECT        dbo.Orders.OrderID, dbo.Orders.StatusID, dbo.Orders.ClientID, dbo.Orders.Comment, dbo.Orders.Discount, dbo.Clients.ClientName, 
                         dbo.OrderStatus.StatusName
FROM            dbo.Clients INNER JOIN
                         dbo.Orders ON dbo.Clients.ClientID = dbo.Orders.ClientID INNER JOIN
                         dbo.OrderStatus ON dbo.Orders.StatusID = dbo.OrderStatus.StatusID
WHERE        (dbo.Orders.StatusID = 1)

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IDX_UserName]    Script Date: 18/01/2014 22:15:52 ******/
CREATE NONCLUSTERED INDEX [IDX_UserName] ON [dbo].[Users]
(
	[UserName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Orders] ADD  CONSTRAINT [DF_Orders_OrderDate]  DEFAULT (getdate()) FOR [OrderDate]
GO
ALTER TABLE [dbo].[ItemsHolidays]  WITH CHECK ADD  CONSTRAINT [FK_ItemsHolidays_Holidays] FOREIGN KEY([HolidayID])
REFERENCES [dbo].[Holidays] ([HolidayID])
GO
ALTER TABLE [dbo].[ItemsHolidays] CHECK CONSTRAINT [FK_ItemsHolidays_Holidays]
GO
ALTER TABLE [dbo].[ItemsHolidays]  WITH CHECK ADD  CONSTRAINT [FK_ItemsHolidays_Items] FOREIGN KEY([ItemsID])
REFERENCES [dbo].[Items] ([ItemID])
GO
ALTER TABLE [dbo].[ItemsHolidays] CHECK CONSTRAINT [FK_ItemsHolidays_Items]
GO
ALTER TABLE [dbo].[Memberships]  WITH CHECK ADD  CONSTRAINT [MembershipEntity_Application] FOREIGN KEY([ApplicationId])
REFERENCES [dbo].[Applications] ([ApplicationId])
GO
ALTER TABLE [dbo].[Memberships] CHECK CONSTRAINT [MembershipEntity_Application]
GO
ALTER TABLE [dbo].[Memberships]  WITH CHECK ADD  CONSTRAINT [MembershipEntity_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([UserId])
GO
ALTER TABLE [dbo].[Memberships] CHECK CONSTRAINT [MembershipEntity_User]
GO
ALTER TABLE [dbo].[OrderItems]  WITH CHECK ADD  CONSTRAINT [FK_OrderItems_Items] FOREIGN KEY([ItemID])
REFERENCES [dbo].[Items] ([ItemID])
GO
ALTER TABLE [dbo].[OrderItems] CHECK CONSTRAINT [FK_OrderItems_Items]
GO
ALTER TABLE [dbo].[OrderItems]  WITH CHECK ADD  CONSTRAINT [FK_OrderItems_Orders] FOREIGN KEY([OrderID])
REFERENCES [dbo].[Orders] ([OrderID])
GO
ALTER TABLE [dbo].[OrderItems] CHECK CONSTRAINT [FK_OrderItems_Orders]
GO
ALTER TABLE [dbo].[Orders]  WITH CHECK ADD  CONSTRAINT [FK_Orders_Clients] FOREIGN KEY([ClientID])
REFERENCES [dbo].[Clients] ([ClientID])
GO
ALTER TABLE [dbo].[Orders] CHECK CONSTRAINT [FK_Orders_Clients]
GO
ALTER TABLE [dbo].[Orders]  WITH CHECK ADD  CONSTRAINT [FK_Orders_OrderStatus] FOREIGN KEY([StatusID])
REFERENCES [dbo].[OrderStatus] ([StatusID])
GO
ALTER TABLE [dbo].[Orders] CHECK CONSTRAINT [FK_Orders_OrderStatus]
GO
ALTER TABLE [dbo].[Profiles]  WITH CHECK ADD  CONSTRAINT [ProfileEntity_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([UserId])
GO
ALTER TABLE [dbo].[Profiles] CHECK CONSTRAINT [ProfileEntity_User]
GO
ALTER TABLE [dbo].[Roles]  WITH CHECK ADD  CONSTRAINT [RoleEntity_Application] FOREIGN KEY([ApplicationId])
REFERENCES [dbo].[Applications] ([ApplicationId])
GO
ALTER TABLE [dbo].[Roles] CHECK CONSTRAINT [RoleEntity_Application]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [User_Application] FOREIGN KEY([ApplicationId])
REFERENCES [dbo].[Applications] ([ApplicationId])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [User_Application]
GO
ALTER TABLE [dbo].[UsersInRoles]  WITH CHECK ADD  CONSTRAINT [UsersInRole_Role] FOREIGN KEY([RoleId])
REFERENCES [dbo].[Roles] ([RoleId])
GO
ALTER TABLE [dbo].[UsersInRoles] CHECK CONSTRAINT [UsersInRole_Role]
GO
ALTER TABLE [dbo].[UsersInRoles]  WITH CHECK ADD  CONSTRAINT [UsersInRole_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([UserId])
GO
ALTER TABLE [dbo].[UsersInRoles] CHECK CONSTRAINT [UsersInRole_User]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Clients"
            Begin Extent = 
               Top = 146
               Left = 791
               Bottom = 242
               Right = 961
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Orders"
            Begin Extent = 
               Top = 6
               Left = 454
               Bottom = 220
               Right = 624
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "OrderStatus"
            Begin Extent = 
               Top = 24
               Left = 790
               Bottom = 120
               Right = 960
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 14
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'AllOrders'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'AllOrders'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[15] 2[25] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Clients"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 102
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Orders"
            Begin Extent = 
               Top = 6
               Left = 454
               Bottom = 136
               Right = 624
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "OrderStatus"
            Begin Extent = 
               Top = 6
               Left = 662
               Bottom = 102
               Right = 832
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'NewOrders'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'NewOrders'
GO
USE [master]
GO
ALTER DATABASE [Glam] SET  READ_WRITE 
GO
