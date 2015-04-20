USE [master]
GO
/****** Object:  Database [Glam]    Script Date: 18/01/2014 22:16:38 ******/
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
/****** Object:  User [dandan]    Script Date: 18/01/2014 22:16:38 ******/
CREATE USER [dandan] FOR LOGIN [dandan] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  DatabaseRole [admin]    Script Date: 18/01/2014 22:16:38 ******/
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
/****** Object:  StoredProcedure [dbo].[GetOrderAndItsItems]    Script Date: 18/01/2014 22:16:38 ******/
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
/****** Object:  StoredProcedure [dbo].[InsertNewOrder]    Script Date: 18/01/2014 22:16:38 ******/
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
/****** Object:  StoredProcedure [dbo].[InsertNewOrderItem]    Script Date: 18/01/2014 22:16:38 ******/
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
/****** Object:  StoredProcedure [dbo].[ProcessNextPendingOrder]    Script Date: 18/01/2014 22:16:38 ******/
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
/****** Object:  StoredProcedure [dbo].[UpdateOrderStatus]    Script Date: 18/01/2014 22:16:38 ******/
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
/****** Object:  Table [dbo].[Applications]    Script Date: 18/01/2014 22:16:38 ******/
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
/****** Object:  Table [dbo].[Clients]    Script Date: 18/01/2014 22:16:38 ******/
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
/****** Object:  Table [dbo].[Holidays]    Script Date: 18/01/2014 22:16:38 ******/
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
/****** Object:  Table [dbo].[Items]    Script Date: 18/01/2014 22:16:38 ******/
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
/****** Object:  Table [dbo].[ItemsHolidays]    Script Date: 18/01/2014 22:16:39 ******/
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
/****** Object:  Table [dbo].[Memberships]    Script Date: 18/01/2014 22:16:39 ******/
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
/****** Object:  Table [dbo].[OrderItems]    Script Date: 18/01/2014 22:16:39 ******/
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
/****** Object:  Table [dbo].[Orders]    Script Date: 18/01/2014 22:16:39 ******/
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
/****** Object:  Table [dbo].[OrderStatus]    Script Date: 18/01/2014 22:16:39 ******/
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
/****** Object:  Table [dbo].[Profiles]    Script Date: 18/01/2014 22:16:39 ******/
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
/****** Object:  Table [dbo].[Roles]    Script Date: 18/01/2014 22:16:39 ******/
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
/****** Object:  Table [dbo].[Users]    Script Date: 18/01/2014 22:16:39 ******/
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
/****** Object:  Table [dbo].[UsersInRoles]    Script Date: 18/01/2014 22:16:39 ******/
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
/****** Object:  View [dbo].[AllOrders]    Script Date: 18/01/2014 22:16:39 ******/
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
/****** Object:  View [dbo].[NewOrders]    Script Date: 18/01/2014 22:16:39 ******/
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
INSERT [dbo].[Applications] ([ApplicationId], [ApplicationName], [Description]) VALUES (N'0f035459-682a-416b-8e0f-4aed8f3a2a34', N'GlamServer', NULL)
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (19884, N'עידן 2000 ערד 513903641')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (19889, N'הגן הנודד 066057233')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (20019, N'אושרת ציוד לגנים 09-2693600')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (20202, N'מעיין היצירה ערד 057385379')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (20940, N'צעצועים חסידה 022520753')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22001, N'דע לי 08-9465111')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22003, N'הופ לגן 052-3476755')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22006, N'יוני דניאלי 514064187')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22008, N'דניאל לגן')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22009, N'דניאלי צעצועים בעמ 513761460')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22015, N'גן גני י-ם 050-2863866')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22016, N'בזוית אחרת 62999289')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22018, N'צבי קל 069381374')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22019, N'לגן ולטף פ"ת 512711060')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22021, N'בר טל 24325243')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22022, N'דף רם בע"מ 512075136')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22023, N'איתר שיווק 510920374')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22025, N'טופ שופ פ"ת 040378937')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22029, N'הגן של נועה 512890898')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22030, N'אוספיס טניה 016670374')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22031, N'מ.פסגה ת"א 513237545')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22033, N'מזרחי שיווק ישראל 511627523')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22034, N'הנייר ראשל"צ 510959141')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22036, N'עיר גנים י-ם 62849922')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22038, N'משחק ומחשבה 512563370')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22040, N'שי לגן 33468273')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22042, N'דניאלי יוסי 058487232')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22060, N'מטמון פלוס 513947036')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22063, N'פלוס לגננת 514429398')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (22100, N'מרכז הגנים והיצירה 513054478')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (23003, N'אלאדין 557173374 09-7672851')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (23004, N'בוטיצ''לי 514461508')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (23007, N'בדרך אל הגן 514349752 2010')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (23016, N'באג לגן נתניה 557793502')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (23027, N'ספרי שולמית-ב.ש')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (23036, N'אי המטמון')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (23460, N'פאזל024573909 -')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (23461, N'גבע')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (23469, N'לגן ולטף דרום 2011 בעמ')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (40526, N'הכל לגן דימונה 23672918')
INSERT [dbo].[Clients] ([ClientID], [ClientName]) VALUES (41101, N'כל בו גן 510846207 03-5793087')
SET IDENTITY_INSERT [dbo].[Holidays] ON 

INSERT [dbo].[Holidays] ([HolidayID], [HolidayName]) VALUES (1, N'תחילת שנה')
INSERT [dbo].[Holidays] ([HolidayID], [HolidayName]) VALUES (2, N'פסח')
INSERT [dbo].[Holidays] ([HolidayID], [HolidayName]) VALUES (3, N'ראש השנה האזרחי')
INSERT [dbo].[Holidays] ([HolidayID], [HolidayName]) VALUES (4, N'חג ההודיה')
INSERT [dbo].[Holidays] ([HolidayID], [HolidayName]) VALUES (5, N'פורים')
INSERT [dbo].[Holidays] ([HolidayID], [HolidayName]) VALUES (6, N'יום הזיכרון/העצמאות')
INSERT [dbo].[Holidays] ([HolidayID], [HolidayName]) VALUES (7, N'יום ירושלים')
INSERT [dbo].[Holidays] ([HolidayID], [HolidayName]) VALUES (8, N'ראש השנה/יום כיפור')
INSERT [dbo].[Holidays] ([HolidayID], [HolidayName]) VALUES (9, N'סתיו')
INSERT [dbo].[Holidays] ([HolidayID], [HolidayName]) VALUES (10, N'חנוכה')
INSERT [dbo].[Holidays] ([HolidayID], [HolidayName]) VALUES (11, N'אביב/פסח')
INSERT [dbo].[Holidays] ([HolidayID], [HolidayName]) VALUES (12, N'לג בעומר')
INSERT [dbo].[Holidays] ([HolidayID], [HolidayName]) VALUES (13, N'שבועות')
INSERT [dbo].[Holidays] ([HolidayID], [HolidayName]) VALUES (14, N'קיץ')
INSERT [dbo].[Holidays] ([HolidayID], [HolidayName]) VALUES (15, N'רמאדן')
INSERT [dbo].[Holidays] ([HolidayID], [HolidayName]) VALUES (16, N'חג המולד')
INSERT [dbo].[Holidays] ([HolidayID], [HolidayName]) VALUES (17, N'איד אל עדה')
INSERT [dbo].[Holidays] ([HolidayID], [HolidayName]) VALUES (18, N'ט"ו בשבט')
SET IDENTITY_INSERT [dbo].[Holidays] OFF
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1007', N'סימניה צבעונית לספר', CAST(10 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1008', N'גזירות ילד קטן', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1009', N'ערכת דיקלומים', CAST(39 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1010', N'כרזה מפל שלום כיתה א', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1011', N'חוברת צביעה בריאת העולם', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1012', N'כרטיסים לספריה', CAST(11 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1013', N'פרחים ללוח מי בא לגן', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1014', N'חוברת ילד קטן הלך לגן', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1016', N'מדבקות א-ב אות פותחת 5 ס"מ', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1017', N'מדבקות חודשי השנה גדולות', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1018', N'פרח סוכריה', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1019', N'כיס שקוף לתאים', CAST(25 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1020', N'מדבקות תאים לצעירים', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1021', N'מדבקות תאים לבוגרים', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1022', N'תליון גמדון', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1023', N'עבודת יצירה ילד קטן', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1024', N'תליון כל הכבוד', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1025', N'תליון ישר כוח', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1026', N'כרזה ברוכים הבאים מפל', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1027', N'פלקט להתחיל עם חיוך', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1028', N'כרזה מפל מתחילים בחיוך', CAST(22 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1030', N'באלו הידיים- תיק עבודות', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1031', N'דפים מעוצבים', CAST(11 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1032', N'כרזה שנה חדשה מתחילה בחיוך', CAST(22 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1033', N'סימניה לספר לצביעה', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1124', N'ערכת סופרים ומשוררים', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1130', N'ערכת כלי משכן', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1228', N'םלקט פירמידת המזון', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1326', N'קישוטי קיר סול מגן דוד', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1336', N'קישוטי קיר סול יונה', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1349', N'תליון מי תורן', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1382', N'סיפור המחשה אני מטייל+ דיסק', CAST(29 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1383', N'סיפור המחשה יום הולדת+ דיסק', CAST(29 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1386', N'סיפור המחשה הדולפין ודג החרב+ דיסק', CAST(29 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1430', N'סיפור המחשה גזור ילד קטן', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1436', N'גב לכיסא אמא שבת', CAST(22 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1448', N'חוברת ליאור בכה', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1454', N'דפים מעוצבים- נעים להודיע', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1458', N'דפי קשר לתיק מפל', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1500', N'שלום כיתה', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1609', N'מדבקות חג שמח', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'1633', N'מדבקות נשיקות 1.6', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2007', N'אגרת ראש השנה תפוח', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2008', N'דפים מעוצבים ראש השנה', CAST(11 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2009', N'כרזה חנוכה שמח זוהרת', CAST(22 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2010', N'יצירה קופסא לדבש', CAST(17 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2012', N'סט שבלונות ראש השנה', CAST(10 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2013', N'סט שקפים ראש השנה', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2014', N'אגרת צביעה מעטפה', CAST(17 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2015', N'גזירות סמלי חג הולוגרמי', CAST(5 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2016', N'אגרת שנה טובה רימון', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2017', N'גזירות סמלי ראש השנה קרטון', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2018', N'גזירות סול ראש השנה', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2019', N'חותמות ספוג ראש השנה', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2020', N'גזירות דבש', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2021', N'פלקט יום כיפור', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2022', N'יצירת צלחת ראש השנה עם גזירות', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2023', N'עבודת יצירה פרח-דבש', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2024', N'סט סמלי מפל גדולים לחגי תשרי', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2025', N'מדבקות רימנוים 3.5 סמ', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2026', N'מדבקות תפוחים 3.5 סמ', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2028', N'ע. יצירה מי מתוק יותר מדבש', CAST(15 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2029', N'מובייל ראש השנה מפל', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2030', N'כרזת שנה טובה', CAST(22 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2031', N'מובייל ראש השנה שקף', CAST(18 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2032', N'סמלי ראש השנה לצביעה וקישוט', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2033', N'סמלי יום כיפור לצביעה וקישוט', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2035', N'גזירות סול ראש השנה נוצץ', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2037', N'מדבקות שנה טובה 3.5 סמ', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2100', N'פלקט סוכות', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2101', N'פלקט סמלי סוכות', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2102', N'ערכת סוכות', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2104', N'גזירות סוכות מקרטון', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2105', N'מדבקות סוכות', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2106', N'שבלונות 4 המינים', CAST(10 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2107', N'פסי קישוט סוכות', CAST(6 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2108', N'יצירה סוכה לבניה', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2109', N'טיפים סוכות', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2111', N'דגלי שמחת תורה צבעוני', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2112', N'גזירות סול ארבעת המינים', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2113', N'דגלי שמחת תורה  לצביעה', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2114', N'מובייל שקף סוכות', CAST(18 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2115', N'כרזה סוכות', CAST(22 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2200', N'פלקט גינה שלי', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2201', N'ערכת גינה', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2202', N'ערכת פירות', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2203', N'ערכת ירקות', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2204', N'מדבקות פירות', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2205', N'מדבקות ירקות', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2206', N'מדבקות גינה', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2207', N'גזירות סול פירות', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2208', N'גזירות ירקות', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2209', N'גזירות כלי גינה', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2210', N'עבודת יצירה גינה שלי', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2213', N'דמויות ילדים וגינה ממפל גזור', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2214', N'גזירות עץ וחלקיו ממפל', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2215', N'יצירה סמלי טו בשבט עם גזירות', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2216', N'עבודת יצירה שתיל צומח', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2217', N'פרחים סול ורוד לבן 5 סמ', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2218', N'פרחים סול ורוד לבן 3 סמ', CAST(6 AS Decimal(18, 0)))
GO
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2219', N'עבודת יצירה התפתחות הצמח', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2220', N'יצירה גינה לצביעה וקישוט', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2221', N'יצירה אליעזר והגזר', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2222', N'יצירה משולבת ילדים שותלים', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2223', N'יצירה אני שותל', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2224', N'כרזה מפל טו בשבט', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2225', N'המחשה מה בפרדס- גזירות גדולות', CAST(22 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2226', N'סלסלה טו בשבט להרכבה', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2227', N'גזירות ירקות גדולים', CAST(22 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2228', N'גזירות פירות גדולים', CAST(22 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2229', N'גזירות סול ירקות', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2230', N'עבודת יצירה גינה עם מדבקות', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2300', N'ערכת כותנה', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2301', N'ערכת סתיו', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2302', N'ערכת פרחי סתיו חורף', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2303', N'כרזה סתיו ממפל', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2304', N'פלקט מבשרי הסתיו', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2305', N'פלקט ברלה', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2306', N'מדבקות סמלי הסתיו', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2307', N'גזירות סמלי הסתיו', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2308', N'פסי קישוט סתיו', CAST(6 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2309', N'חוברת טיפים סתיו וחורף', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2310', N'יצירה סתיו לצביעה וקישוט', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2313', N'יצירה סתיו לצביעה', CAST(11 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2315', N'גזירות סול עלים', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2316', N'מדבקות חילזון', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2317', N'מדבקות פטריות', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2318', N'מדבקות עלים', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2319', N'מדבקות ציפורים', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2320', N'יצירה החילזון וביתו', CAST(17 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2321', N'פלקט בינוני נחליאלי', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2322', N'פלקט בינוני חילזון', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2323', N'סט שבלונות סתיו', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2324', N'גזירות סול סתיו וחורף', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2325', N'גזירות עלים קרטון', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2326', N'מובייל מפל סתיו', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2327', N'עבודת יצירה נחליאלי', CAST(17 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2328', N'המחשה נחליאלי+ דיסק', CAST(36 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2400', N'ערכת חנוכה', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2401', N'ערכת מקורות האור', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2402', N'ערכת הזית', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2403', N'פלקט חנוכה', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2404', N'פלקט סמלי חנוכה', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2405', N'פלקט חנה זלדה', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2406', N'פלקט גברת קרש', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2407', N'פלקט חנוכיה פעיל', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2408', N'הזמנה- כד', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2409', N'הזמנה- נר', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2410', N'חוברת טיפים חנוכה', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2411', N'גזירות חנוכה מודפסות', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2412', N'גזירות חנוכה מקרטון כסף/ זהב', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2413', N'גזירות סמלי חנוכה סול', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2414', N'קישוטי קיר זוהר לחנוכה', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2415', N'מדבקות דש חנוכה', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2416', N'מדבקות סמלי חנוכה 2.5', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2417', N'יצירה חנוכה+ גזירות', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2418', N'עבודת יצירה חנה זלדה', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2419', N'עבודת יצירה גברת קרש', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2420', N'עבודת יצירה חנוכה שמחעם מסגרת', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2421', N'כרזת חנוכה תלת מימד', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2422', N'כתר חנוכה', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2423', N'נרות סול חנוכה', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2424', N'יצירה עץ זית עם מדבקות', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2425', N'דפים מעוצבים חנוכה', CAST(11 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2426', N'גזירות סול סמלי חנוכה גדול', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2427', N'שבלונות חנוכה', CAST(10 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2428', N'סביבון שי לחג', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2429', N'שטרות כסף', CAST(6 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2430', N'שקפים חנוכה', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2431', N'פלקט הלביבה שהתגלגלה', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2433', N'הזמנות זוהרות חנוכה', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2434', N'גזירות סמלי חנוכה זוהרות', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2435', N'מדבקות דש חנוכה זוהרות', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2436', N'מדבקות סמלי חנוכה זוהר 3.5', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2437', N'עבודת יצירה עץ זית עם גזירות', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2438', N'מטבעות כסף', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2439', N'מובייל חנוכה', CAST(18 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2440', N'חותמות ספוג חנוכה', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2441', N'כרזה מפל חנוכה', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2442', N'יצירה חנוכה לצביעה וקישוט', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2443', N'נרות סול נצנץ בינוני', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2444', N'ברכות חנוכה עם תמונת הילד', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2445', N'נרות סול נצנץ גדול', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2446', N'סמלי חנוכה סול נצנץ בינוני', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2447', N'סמלי חנוכה סול נצנץ גדול', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2448', N'סמלי חנוכה 4 תמונות', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2449', N'עבודת יצירה חנוכיה עם מדבקות', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2451', N'חוברת חנה זלדה', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2452', N'חוברת גברת קרש', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2453', N'נרות סול חנוכה בינוני', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2455', N'מדבקות שלהבת', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2457', N'פסי קישוט קרטון זוהר', CAST(10 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2458', N'יצירה סביבון לצביעה והרכבה', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2459', N'סמלי חנוכה זוהרים באולטרה', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2460', N'יצירה חנוכה עם מדבקות', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2461', N'פסי קישוט זוהרים באולטרה חנוכה', CAST(6 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2500', N'ערכת חורף', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2501', N'פלקט חורף', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2502', N'פלקט סמלי חורף', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2503', N'פלקט שלולי', CAST(13 AS Decimal(18, 0)))
GO
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2504', N'פלקט מגפיים', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2505', N'פלקט המטריה הגדולה של אבא', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2506', N'פלקט משיב הרוח מוריד הגשם', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2507', N'פלקט הענן של ערן', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2508', N'מדבקות סמלי חורף', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2509', N'גזירות סמלי חורף', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2510', N'גזירות המטריה הגדולה של אבא', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2511', N'גזירות סול עננים וטיפות גשם', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2512', N'עבודת יצירה חורף', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2513', N'פסי קישוט חורף', CAST(6 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2514', N'עץ יצירה המטריה הגדולה תלת מימד', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2515', N'מדבקות טיפות גשם', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2516', N'פלקט נרקיס מלך הביצה', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2517', N'ערכת מראות השמים', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2518', N'ערכת מקורות המים', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2519', N'ערכת שימושי המים', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2520', N'ע. יצירה המטריה הגדולה עם גזירות', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2521', N'דפים מעוצבים חורף', CAST(11 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2522', N'פלקט מחזור המים בטבע', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2523', N'פלקט חבל על כל טיפה', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2524', N'סט שבלונות חורף', CAST(10 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2525', N'דמויות ילדים בחורף מפל גזור', CAST(22 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2527', N'כרזה מפל חורף', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2528', N'יצירה חורף לצביעה וקישוט', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2529', N'מובייל חורף מפל', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2530', N'יצירה ילדה בגשם עם מדבקות', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2531', N'יצירה המטריה של אבא עם מדבקות', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2532', N'מדבקות טיפות גשם 1.6', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2600', N'ערכת שירי ביאליק', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2601', N'חוברת צביעה שירי ביאליק', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2602', N'תמונה ביאליק', CAST(3 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2603', N'רוץ בין סוסים/קן לציפור', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2700', N'ערכת טו בשבט', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2701', N'ערכת עצים', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2702', N'ערכת מחזור חיי הצמח', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2703', N'ערכת החקלאי', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2704', N'ערכת פירות הדר', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2705', N'מדבקות דש טו בשבט', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2706', N'גזירות מודפסות עצים', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2707', N'גזירות מודפסות טו בשבט', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2708', N'יצירה משולבת טו בשבט', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2710', N'ע. יצירה פרי הדר עם מדבקות', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2711', N'עבודת יצירה שישה בשקיק', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2712', N'עבודת יצירה האורן הבודד', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2713', N'יצירה עץ תלת מימד', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2714', N'חוברת טיפים טו בשבט', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2716', N'מדבקות שקדיה', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2717', N'גזירות סול עץ השקדייה', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2718', N'מדבקות פרי הדר 2.5', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2719', N'עבודת יצירה התפתחות הצמח', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2720', N'גזירות סול פרחים ועלים', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2722', N'פלקט טו בשבט', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2723', N'פלקט אוריינות טו בשבט', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2724', N'פלקט פרי הדר', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2725', N'פלקט זרע של צנונית', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2726', N'פלקט שישה בשקיק', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2727', N'פלקט האורן הבודד', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2728', N'פלקט בינוני טו בשבט', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2729', N'מדבקות פירות יבשים', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2730', N'פלקט עץ ומוצריו', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2731', N'גזירות שישה בשקיק', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2732', N'גזירות פרי הדר מודפס', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2733', N'כתרים טו בשבט', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2734', N'דפים מעוציבים טו בשבט', CAST(11 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2735', N'יצירה השקדיה פורחת עם מדבקות', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2737', N'פתגמים טו בשבט', CAST(10 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2738', N'חוברת שישה בשקיק', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2739', N'פרח סול נצנץ 3 סמ', CAST(7 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2740', N'פרח סול נצנץ 5 סמ', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2741', N'חותמות ספוג עלים ופרחים', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2742', N'עץ שקדיה סול נצנץ עם פרחים', CAST(10 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2743', N'סול עלים ופרחים נצנץ', CAST(10 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2744', N'מובייל טו בשבט', CAST(18 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2745', N'סמלי טו בשבט לצביעה וקישוט', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2746', N'שקף עץ שקדייה', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2748', N'תליון טו בשבט', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2749', N'שבלונה טו בשבט', CAST(10 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2750', N'מדבקות פרי הדר 3.5', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2752', N'כתר טו בשבט לצביעה', CAST(17 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2753', N'סיפור שקדיה+ דיסק', CAST(36 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2754', N'יצירה אנו מכינים מיץ עם מדבקות', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2755', N'מדבקות שקדיה 1.7', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2756', N'עבודת יצירה סלסלה צביעה והרכבה', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2757', N'עלים מסול דביק', CAST(3 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2758', N'ע. יצירה סלסלת פירות עם מדבקות', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2800', N'ערכת משפחה', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2801', N'חמסה עם מסגרת קרטון ביצוע', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2802', N'עבודה זר למשפחתי היקרה', CAST(6 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2804', N'עבודה אני וביתי', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2805', N'יצירה בית ומשפחה משולב', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2806', N'פלקט בית ומשפחה', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2807', N'פלקט בינוני קשר משפחתי', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2808', N'פלקט בינוני יום המפשחה', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2809', N'חוברת טיפים יום המשפחה', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2810', N'דמויות משפחה גדולות', CAST(22 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2811', N'דמויות משפחה קומיקס', CAST(6 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2812', N'דמויות סול משפחה', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2813', N'חותמות ספוג משפחה', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2814', N'מדבקות דש ליום המשפחה', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2815', N'גזירות סול לבבות', CAST(8 AS Decimal(18, 0)))
GO
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2816', N'חותמות ספוג לבבות', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2817', N'גזירות סול חמסה', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2818', N'דמויות מהעולם', CAST(6 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2819', N'דפים מעוצבים ליום המשפחה', CAST(11 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2820', N'עבודה בית ומשפחה', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2821', N'מובייל ברכות שקף', CAST(18 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2822', N'לב עם מסגרת מקרטון ביצוע', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2823', N'איגרת לב למשפחה', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2824', N'אגרת חמסה ברכת הבית', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2825', N'עבודת יצירה בית להרכבה', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2826', N'יצירה מעטפה צבעונית', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2828', N'סלסלת פרחים למשפחה', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2829', N'יצירה מעטפה לצביעה', CAST(17 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2830', N'גזירות משפחה מקרטון', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2832', N'סט שבלונות בית ומשפחה', CAST(10 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2833', N'לבבות סול נוצץ', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2834', N'מדבקות לב 1.6', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2835', N'מדבקות לב 2.5', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2837', N'ברכת הבית מקרטון', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2838', N'כרזה ליום המשפחה', CAST(22 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2839', N'סמלי משפחה לצביעה וקישוט', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2840', N'אגרת ברכה נפתחת למשפחה', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2842', N'קופסאת מתנה קטנה', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2900', N'ערכה פורים', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2901', N'ערכת תחפושות בטבע', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2902', N'משלוח מנות תיק', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2903', N'מובייל שקף לפורים', CAST(18 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2904', N'יצירה רעשן', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2905', N'כרזה מפל חגיגית פורים', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2906', N'זוג ליצני מפל להרכבה', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2908', N'יצירה פורים שמח עם גזירות', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2909', N'מגילת אסתר לצביעה', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2910', N'מגילת אסתר צבעונית', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2911', N'סט יצירה מסכות', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2912', N'עבודת יצירה מעשה בכובעים', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2913', N'עבודת יצירה הבעות ליצן', CAST(17 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2914', N'גזירות סמלי פורים', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2916', N'גזירות דמויות המגילה', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2917', N'דפים מעוצבים פורים', CAST(11 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2918', N'יצירה כובע ליצן להרכבה', CAST(17 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2919', N'משלוח מנות אוזן המן', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2920', N'מדבקות סמלי פורים', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2921', N'שקפים לצביעה פורים', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2922', N'מדבקות ליצנים', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2923', N'מדבקות פורים שמח', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2924', N'שבלונות פורים', CAST(10 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2925', N'חוברת טיפים פורים', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2928', N'פלקט פורים שמח בינוני', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2930', N'פלקט סמלי פורים', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2931', N'פלקט דמויות המגילה', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2932', N'פלקט מעשה באוזן המן', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2933', N'פלקט מעשה בכובעים', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2934', N'פלקט הביצה שהתחפשה', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2935', N'גזירות סול סמלי פורים', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2936', N'חותמות ספוג סמלי פורים', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2937', N'יצירה קופת צדקה לבניה', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2938', N'סט 5 כותרות לפורים', CAST(6 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2939', N'גזירות מעשה באוזן המן', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2940', N'עבודת יצירה ליצן תלת מימד', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2942', N'יצירה ליצן להרכבה', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2943', N'ליצנים לצביעה וקישוט', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2944', N'פלקט פורים שמח זוהר', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2945', N'ערכת קישוטי קיר זוהר לפורים', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2946', N'דמויות המגילה גדולות ממפל', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2947', N'שבלונה אומנותית פורים', CAST(6 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2948', N'סיפורילות לפורים', CAST(23 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2949', N'ערכת ארבע מצוות לפורים', CAST(10 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2950', N'סמלי פורים מסול נצנצים', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2951', N'כוכב מסול נוצץ', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2952', N'כתא מלך/ מלכה ליצירה פורים', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2953', N'כרזה פורים שמח', CAST(22 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2954', N'גזירות סול ליצנים', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2955', N'גזירות סול ליצנים נצנץ', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2957', N'עבודת יצירה ליצן לצביעה עם מדבקות', CAST(17 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'2961', N'הסוס של המן', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3007', N'עבודת יצירה קערה עם מדבקות', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3008', N'מדבקות דש פסח', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3009', N'מדבקות לקערת פסח', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3010', N'מדבקות סמלי פסח', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3011', N'מגש מצות', CAST(15 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3012', N'עבודת יצירה שלושת הפרפרים', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3013', N'עבודת יצירה פירמידה', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3014', N'עבודה יצירה פסח כשר ושמח', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3015', N'עבודת יצירה פרפרים באביב', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3016', N'עבודת יצירה פרחים באביב', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3018', N'עבודת יצירה משה בתיבה', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3019', N'יצירה משה ואהרון', CAST(10 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3021', N'עבודת יצירה בדיקת חמץ', CAST(17 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3022', N'גזירות סמלי פסח מודפסות', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3023', N'גזירות פרפרים', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3024', N'מדבקות פרפרים 2.5', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3025', N'מדבקות פרחים 2.5', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3026', N'שבלונות סמלי חג פסח', CAST(10 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3027', N'פלקט פסח כשר ושמח', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3028', N'פלקט סמלי פסח', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3029', N'פלקט אביב', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3030', N'פלקט סמלי אביב', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3031', N'פלקט הכוס של אליהו', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3032', N'פלקט שלושת הפרפרים', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3033', N'פלקט אגוז של זהב', CAST(13 AS Decimal(18, 0)))
GO
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3034', N'ערכת היין', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3036', N'ערכת פרפר טוואי המשי', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3037', N'ערכת פרחי אביב', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3038', N'חוברת טיפים פסח', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3040', N'גזירות אגוז של זהב', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3041', N'גזירות כוסו של אליהו', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3042', N'גזירות סול פרפרים', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3043', N'גזירות סול בקבוקים וכוסות', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3044', N'דפים מעוצבים פסח', CAST(11 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3045', N'דפים מעוצבים אביב', CAST(11 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3046', N'רקעי קישוט אביב', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3047', N'פסי קישוט אביב', CAST(6 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3049', N'יצירה ספירת העומר', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3051', N'חותמות ספוג פסח', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3052', N'חותמות ספוג פרפרים', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3053', N'שקפים לפסח', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3054', N'סמלי אביב ממפל', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3055', N'שולחן סדר פסח ממפל', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3056', N'מדבקות חרקים 2.2', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3057', N'מדבקות פרחים 1.6', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3058', N'מדבקות דבורה 2.5 סמ', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3059', N'מדבקות חיפושית 1.6', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3060', N'מדבקות חיפושית 2.5', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3061', N'סמלי אביב לצביעה וקישוט', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3062', N'מובייל שקף אביב', CAST(18 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3063', N'שבלונה אביב', CAST(10 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3064', N'כרזה מפל אביב הגיע', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3065', N'פרחים גדולים', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3066', N'פרפרים גדולים', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3067', N'כרזה מפל פסח', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3069', N'מובייל פסח', CAST(18 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3070', N'יצירה ניקיון הבית', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3071', N'סול נצנצים בקבוקים וכוסות', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3072', N'סול נצנצים פרפרים', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3073', N'הגדה גדולה לפסח', CAST(2 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3074', N'ערכת שמות חג הפסח', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3075', N'גזירות פרחים מקרטון', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3076', N'ערכת סיפור ההגדה', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3077', N'סמלי פסח לצביעה וקישוט', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3078', N'סיפור המחשה מעשה במצה שלא מצאה', CAST(29 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3079', N'פלקט משה בתיבה', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3080', N'יצירה חיפושית להרכבה', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3081', N'יצירה פרפר עם מדבקות', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3082', N'יצירה דבורה להרכבה', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3083', N'סיפור המחשה נסיכולה מלוכלכולה', CAST(36 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3100', N'פלקט יום העצמאות', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3101', N'פלקט ארץ ישראל שלי', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3102', N'פלקט מפת ארץ ישראל', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3103', N'פוסטר קטן סמל המדינה', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3104', N'פוסטר קטן דגל המדינה', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3105', N'פוסטר קטן המנון התקווה', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3106', N'פוסטר קטן נשיא המדינה', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3107', N'פוסטר קטן ראש הממשלה', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3108', N'פוסטר קטן רמטכל', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3109', N'פוסטר קטן הרצל', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3110', N'פוסטר קטן תפילה לשלום המדינה', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3111', N'פוסטר מגילת העצמאות', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3112', N'ערכת יום העצמאות ויום הזיכרון', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3113', N'ערכת תמונות סמל המדינה', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3114', N'ערכת תמונות דגל המדינה', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3115', N'מדבקות דש עצמאות', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3116', N'מדבקות בינוניות סמל', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3117', N'מדבקות בינוניות דגל', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3118', N'מדבקות מיני סמל', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3119', N'מדבקות דגלים 1.6', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3120', N'דגלים מנייר לקישוט', CAST(6 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3121', N'סמלים מנייר לקישוט', CAST(6 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3122', N'יצירה חוגגים עצמאות', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3123', N'יצירה חג היום לישראל', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3124', N'תעודת זהות', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3125', N'חוברת טיפים עצמאות', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3126', N'פלקט יום השואה בינוני', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3127', N'שבלונות סמלי עצמאות', CAST(10 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3128', N'גזירות סול יונה כחול לבן', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3129', N'חותמות ספוג עצמאות', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3130', N'גזירות סול פרחים כחול לבן', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3131', N'גזירות סול מגן דוד כחול לבן', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3132', N'גזירות סמלי עצמאות מודפסות', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3133', N'פסיפס סול יום העצמאות', CAST(10 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3134', N'מדבקות סמלי עצמאות 2.5', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3135', N'מדבקות דגלים 2.5', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3136', N'יצירה הנפת הדגל', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3137', N'פלקט תעודת זהות', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3138', N'פלקט יזכור', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3139', N'פלקט מפת א"י צרה', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3140', N'ערכת נשיאי המדינה', CAST(15 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3141', N'ערכת ראשי ממשלה', CAST(15 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3142', N'פלקט ארצנו היפה', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3143', N'ערכת נופים ואתרים', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3144', N'ערכת שבעה עשורים', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3145', N'פסי קישוט עצמאות', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3146', N'שקפים ליום העצמאות', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3147', N'מדבקות מגני דוד 2.5', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3148', N'ערכת לאום', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3150', N'מובייל יום העצמאות', CAST(18 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3151', N'סמלי המדינה לצביעה וקישוט', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3152', N'כובעי יום העצמאות', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3153', N'יצירה מפה ואתרים', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3154', N'כרזה עצמאות לישראל ממפל', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3155', N'מדבקות כחול לבן 2.5', CAST(4 AS Decimal(18, 0)))
GO
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3156', N'מדבקות כחול לבן 1.6', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3157', N'מדבקות כחול לבן מטרה', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3159', N'סמלי עצמאות וצהל לצביעה וקישוט', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3160', N'סול פרחים נצנץ', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3161', N'סול מגן דוד נצנץ', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3162', N'סול יונים נצנץ', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3164', N'יצירה יונה להרכבה', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3165', N'יצירה עוגת יום הולדת למדינה', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3200', N'ערכת לג בעומר', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3201', N'פלקט לג בעומר', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3202', N'פלקט סמלי לג בעומר', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3203', N'חוברת טיפים לג בעומר', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3205', N'יצירה מסביב למדורה', CAST(17 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3206', N'ערכת סיפור לג בעומר', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3207', N'גזירות סמלי לג בעומר', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3208', N'שקפים לג בעומר', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3209', N'גזירות סול סמלי לג בעומר', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3210', N'פסיפס סול לג בעומר', CAST(10 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3211', N'מדבקות סמלי לג בעומר', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3212', N'מדבקות מדורה', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3213', N'מקלות קרטיב לג בעומר', CAST(10 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3214', N'יצירה מדורה תלת מימד', CAST(17 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3215', N'פלקט ספירת העומר', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3217', N'סמלי לג בעומר לצביעה וקישוט', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3218', N'פלקט מדורה בינוני', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3219', N'שבלונה לג בעומר', CAST(10 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3220', N'מדבקות עומר צבעוני 2.5', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3221', N'מדבקות עומר צבעוני 1.6', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3222', N'מדבקות עומר צבעוני מטרה', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3223', N'כרזה מפל לג בעומר', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3224', N'חותמות ספוג לג בעומר', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3225', N'יצירה דליק לא דליק', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3226', N'מדבקות דליק לא דליק', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3227', N'ערכה מה לא עושים בספירת העומר', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3426', N'יצירה סלסלה תלת מימד', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3700', N'פלקט אני וגופי', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3701', N'פלקט אני ופני', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3702', N'פלקט חושים', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3703', N'ערכת חושים', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3705', N'עבודת יצירה אני וגופי', CAST(17 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3706', N'עבודת יצירה אני ופני', CAST(17 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3707', N'טיפים אני וגופי', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3738', N'מדבקות פרפרים 3.5', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3800', N'שבלונות שבת', CAST(10 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3801', N'שקפים שבת', CAST(16 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3802', N'גזירות שבת קרטון', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3805', N'מדבקות דש אמא של שבת', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3806', N'מדבקות דש אבא של שבת', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3807', N'כתר אמא של שבת', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3808', N'כתר אבא של שבת', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3809', N'דפים מעוצבים שבת', CAST(11 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3811', N'פלקט סמלי שבת', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3812', N'פלקט שבת שלום', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3813', N'ערכת שבת', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3814', N'מדבקות סמלי שבת', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3815', N'מדבקות שבת שלום', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3816', N'שבלונות סמלים יהודיים', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3817', N'חוברת טיפים שבת', CAST(12 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3818', N'מובייל שקף שבת', CAST(18 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3820', N'מדבקות דש שבת', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3821', N'סמלי שבת לצביעה וקישוט', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3822', N'כרזה שבת שלום מפל', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3823', N'פלקט אבא אמא שבת', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3824', N'תליון אמא אבא שבת', CAST(7 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3825', N'סיפור המחשה פרפרים של שישישבת', CAST(39 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3836', N'קופסאת מתנה גדולה', CAST(21 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3900', N'גב לכיסא יום הולדת', CAST(22 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3901', N'אלבום או תיק יום הולדת', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3902', N'חוברת יום הולדת', CAST(14 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3903', N'דפים מעוצבים יום הולדת', CAST(11 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3904', N'כתרים ליום הולדת', CAST(19 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3905', N'מדבקות דש ליום הולדת', CAST(8 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3906', N'דיסק יום הולדת', CAST(9 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3907', N'כרזה ופלקט מפל יום הולדת', CAST(23 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3908', N'פלקט סמלי יום הולדת', CAST(13 AS Decimal(18, 0)))
INSERT [dbo].[Items] ([ItemID], [ItemName], [ItemPrice]) VALUES (N'3909', N'מדבקות יום הולדת', CAST(4 AS Decimal(18, 0)))
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1008')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1009')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1010')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1011')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1012')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1013')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1014')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1016')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1017')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1018')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1019')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1020')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1021')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1022')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1023')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1024')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1025')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1026')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1027')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1028')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1030')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1031')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1032')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1033')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1228')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1430')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1454')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (1, N'1458')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'1609')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2215')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2216')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2217')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2218')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2219')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2223')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2224')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2226')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2700')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2701')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2702')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2703')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2705')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2706')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2707')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2708')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2711')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2712')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2713')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2714')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2716')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2717')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2720')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2722')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2723')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2725')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2726')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2727')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2728')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2729')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2730')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2731')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2733')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2734')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2735')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2738')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2739')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2740')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2741')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2742')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2743')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2744')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2745')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2746')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2748')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2749')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2752')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2753')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2755')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2756')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2757')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'2758')
INSERT [dbo].[ItemsHolidays] ([HolidayID], [ItemsID]) VALUES (18, N'3426')
INSERT [dbo].[Memberships] ([UserId], [ApplicationId], [Password], [PasswordFormat], [PasswordSalt], [Email], [PasswordQuestion], [PasswordAnswer], [IsApproved], [IsLockedOut], [CreateDate], [LastLoginDate], [LastPasswordChangedDate], [LastLockoutDate], [FailedPasswordAttemptCount], [FailedPasswordAttemptWindowStart], [FailedPasswordAnswerAttemptCount], [FailedPasswordAnswerAttemptWindowsStart], [Comment]) VALUES (N'7d64d977-25d7-4e10-b719-35a66e5be9e2', N'0f035459-682a-416b-8e0f-4aed8f3a2a34', N'CRyBrR1soP8T6suj+ehLKVrIpi8IWqouaboi6VOSYpU=', 1, N'UsW7gqbkhwGwvrWnsPa1gA==', N'jmanager@myemail.com', N'My dog name', N'7LEOGMxyGfouxp4yGl2JBTPHZLCZUpfJXXSHx/ONCJ4=', 1, 0, CAST(0x0000A2950166724A AS DateTime), CAST(0x0000A2950166724A AS DateTime), CAST(0x0000A2950166724A AS DateTime), CAST(0xFFFF2FB300000000 AS DateTime), 0, CAST(0xFFFF2FB300000000 AS DateTime), 0, CAST(0xFFFF2FB300000000 AS DateTime), NULL)
INSERT [dbo].[Memberships] ([UserId], [ApplicationId], [Password], [PasswordFormat], [PasswordSalt], [Email], [PasswordQuestion], [PasswordAnswer], [IsApproved], [IsLockedOut], [CreateDate], [LastLoginDate], [LastPasswordChangedDate], [LastLockoutDate], [FailedPasswordAttemptCount], [FailedPasswordAttemptWindowStart], [FailedPasswordAnswerAttemptCount], [FailedPasswordAnswerAttemptWindowsStart], [Comment]) VALUES (N'ff44e525-d68c-47a8-81fd-5b2a752531f5', N'0f035459-682a-416b-8e0f-4aed8f3a2a34', N'NdmcNdUO0VF3yBW+jygPXHwTZ6gZO4kuboMCaUuX1eA=', 1, N'O5A+UCqXGsk7nIDvpcDcFw==', N'danfromisrael@gmail.com', N'First pet?', N'34CiyRLCsSdkZjCwy2eFDnyieDzyDM7AvKwE3seL+1I=', 1, 0, CAST(0x0000A295016671D7 AS DateTime), CAST(0x0000A2B70132DDE4 AS DateTime), CAST(0x0000A295016671D7 AS DateTime), CAST(0xFFFF2FB300000000 AS DateTime), 0, CAST(0xFFFF2FB300000000 AS DateTime), 0, CAST(0xFFFF2FB300000000 AS DateTime), NULL)
INSERT [dbo].[Memberships] ([UserId], [ApplicationId], [Password], [PasswordFormat], [PasswordSalt], [Email], [PasswordQuestion], [PasswordAnswer], [IsApproved], [IsLockedOut], [CreateDate], [LastLoginDate], [LastPasswordChangedDate], [LastLockoutDate], [FailedPasswordAttemptCount], [FailedPasswordAttemptWindowStart], [FailedPasswordAnswerAttemptCount], [FailedPasswordAnswerAttemptWindowsStart], [Comment]) VALUES (N'3201f2fe-4370-49b5-a8de-9ff04a4249c6', N'0f035459-682a-416b-8e0f-4aed8f3a2a34', N'D7RMu8tC8/G2yteOi80Wv3EYTFBr+QKmNnHL8+/xh2M=', 1, N'gAuwfTE4UZuPUXAM9fMgvA==', N'yossi@myemail.com', N'My dog name', N'X+iJtSi2WhjRUw8zV3NEQ6Y8gEQWfLis6Fj8Yb5Qvik=', 1, 0, CAST(0x0000A29501667266 AS DateTime), CAST(0x0000A29501739405 AS DateTime), CAST(0x0000A29501667266 AS DateTime), CAST(0xFFFF2FB300000000 AS DateTime), 0, CAST(0xFFFF2FB300000000 AS DateTime), 0, CAST(0xFFFF2FB300000000 AS DateTime), NULL)
INSERT [dbo].[Memberships] ([UserId], [ApplicationId], [Password], [PasswordFormat], [PasswordSalt], [Email], [PasswordQuestion], [PasswordAnswer], [IsApproved], [IsLockedOut], [CreateDate], [LastLoginDate], [LastPasswordChangedDate], [LastLockoutDate], [FailedPasswordAttemptCount], [FailedPasswordAttemptWindowStart], [FailedPasswordAnswerAttemptCount], [FailedPasswordAnswerAttemptWindowsStart], [Comment]) VALUES (N'2197afef-0362-4c7b-8784-be08477e3064', N'0f035459-682a-416b-8e0f-4aed8f3a2a34', N'OqK7kBKwkd8XcdZGpmcgYP4l8jx80oUPDDRTJ33GXcc=', 1, N'O9dUMxqOmD9uf2cV/N4BNQ==', N'maykoraz@gmail.com', N'My BF nick name', N'EV5vtNaBiFaVmxEU+vp7lgaYryx4FjxG80ozMCL9ZeQ=', 1, 0, CAST(0x0000A2950166721A AS DateTime), CAST(0x0000A2B700FD12E7 AS DateTime), CAST(0x0000A2950166721A AS DateTime), CAST(0xFFFF2FB300000000 AS DateTime), 0, CAST(0xFFFF2FB300000000 AS DateTime), 0, CAST(0xFFFF2FB300000000 AS DateTime), NULL)
INSERT [dbo].[Memberships] ([UserId], [ApplicationId], [Password], [PasswordFormat], [PasswordSalt], [Email], [PasswordQuestion], [PasswordAnswer], [IsApproved], [IsLockedOut], [CreateDate], [LastLoginDate], [LastPasswordChangedDate], [LastLockoutDate], [FailedPasswordAttemptCount], [FailedPasswordAttemptWindowStart], [FailedPasswordAnswerAttemptCount], [FailedPasswordAnswerAttemptWindowsStart], [Comment]) VALUES (N'3dc5f705-7701-4859-9ecc-eb72d806e47b', N'0f035459-682a-416b-8e0f-4aed8f3a2a34', N'kGlt6bPFQzTelHveOCQY7my4uzsV1zefFs2FGCDfCHI=', 1, N'h+gP7CV6CKG7xPQtmJLVbA==', N'shanitob@gmail.com', N'My dog name', N'hpuxxRI4Q4mnN63jxMtD1Knl73YgxQPK6yfMxtvzgXM=', 1, 0, CAST(0x0000A2950166722D AS DateTime), CAST(0x0000A2950166722D AS DateTime), CAST(0x0000A2950166722D AS DateTime), CAST(0xFFFF2FB300000000 AS DateTime), 0, CAST(0xFFFF2FB300000000 AS DateTime), 0, CAST(0xFFFF2FB300000000 AS DateTime), NULL)
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1008', 1053, 56, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1008', 1056, 4, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1008', 1060, 12, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1008', 1062, 56, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1009', 1055, 12, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1009', 1057, 56, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1009', 1061, 44, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1009', 1062, 34, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1010', 1054, 56, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1010', 1058, 23, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1010', 1063, 23, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1011', 147, 20, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1011', 1055, 12, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1011', 1056, 34, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1011', 1059, 56, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1011', 1063, 56, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1011', 1064, 3, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 102, 5, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 103, 4, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 104, 11, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 105, 12, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 106, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 107, 20, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 108, 11, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 109, 11, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 110, 11, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 111, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 112, 5, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 113, 5, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 114, 1, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 115, 5, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 116, 11, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 117, 20, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 118, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 119, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 120, 5, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 121, 6, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 122, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 123, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 124, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 125, 2, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 126, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 128, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 129, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 130, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 131, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 133, 3, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 134, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 135, 5, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 136, 2, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 137, 2, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 138, 2, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 1052, 5, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 1053, 56, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 1060, 34, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1012', 1061, 34, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1013', 1056, 12, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1014', 149, 20, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1014', 1052, 5, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1014', 1061, 23, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1021', 149, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1032', 149, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1349', 149, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1448', 149, 20, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'1500', 1052, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2012', 147, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2018', 147, 20, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2018', 148, 20, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2020', 148, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2024', 148, 20, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2025', 148, 20, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2033', 147, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2106', 147, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2112', 147, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2112', 148, 20, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2115', 147, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2205', 144, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2209', 144, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2210', 140, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2214', 140, 3, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2217', 140, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2217', 144, 20, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2218', 144, 30, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2224', 140, 5, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2224', 144, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2225', 140, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2225', 143, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2400', 145, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2400', 146, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2410', 146, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2413', 145, 30, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2418', 146, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2419', 145, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2427', 145, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2427', 146, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2430', 146, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2434', 146, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2436', 145, 20, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2436', 146, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2439', 146, 10, CAST(0 AS Decimal(18, 0)))
GO
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2449', 146, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2452', 146, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2500', 142, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2511', 142, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2527', 144, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2532', 140, 5, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2600', 143, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2601', 144, 20, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2700', 1, 152, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2700', 2, 5, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2700', 3, 6, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2700', 4, 8, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2700', 5, 162, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2700', 6, 80, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2700', 7, 15, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2700', 8, 173, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2701', 9, 41, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2701', 10, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2701', 11, 153, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2701', 12, 51, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2701', 13, 7, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2701', 14, 152, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2701', 15, 5, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2701', 16, 6, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2701', 17, 8, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2701', 18, 162, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2701', 19, 80, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2701', 20, 15, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2701', 21, 173, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2701', 22, 44, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2701', 143, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2702', 142, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2703', 24, 56, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2703', 25, 7, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2703', 26, 39, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2703', 27, 61, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2703', 28, 15, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2703', 29, 127, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2703', 30, 13, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2703', 31, 6, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2703', 32, 18, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2703', 33, 9, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2703', 34, 58, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2703', 35, 37, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2703', 36, 16, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2703', 37, 5, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2703', 38, 48, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2703', 39, 2, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2704', 143, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2706', 144, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2707', 40, 25, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2707', 41, 131, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2707', 42, 16, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2707', 43, 3, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2707', 44, 134, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2707', 45, 5, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2707', 46, 157, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2707', 47, 31, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2707', 48, 22, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2707', 49, 140, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2707', 50, 11, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2707', 144, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2708', 51, 22, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2708', 52, 4, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2708', 53, 32, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2708', 54, 5, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2708', 55, 4, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2708', 56, 12, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2708', 57, 5, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2708', 58, 22, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2711', 59, 147, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2711', 60, 27, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2711', 61, 219, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2711', 62, 110, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2711', 63, 198, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2711', 64, 11, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2711', 65, 15, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2711', 66, 77, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2711', 67, 16, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2712', 68, 32, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2712', 69, 24, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2712', 70, 175, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2712', 71, 11, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2712', 72, 4, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2712', 73, 98, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2712', 74, 14, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2712', 75, 5, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2712', 76, 107, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2712', 77, 5, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2713', 78, 4, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2713', 79, 11, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2713', 80, 139, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2713', 81, 14, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2713', 82, 194, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2713', 83, 1, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2713', 84, 136, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2713', 85, 45, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2713', 86, 5, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2713', 87, 84, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2720', 144, 20, CAST(0 AS Decimal(18, 0)))
GO
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2729', 144, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2739', 144, 30, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2740', 144, 20, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2741', 144, 20, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2743', 144, 20, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2749', 141, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2749', 143, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2752', 144, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2757', 144, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2800', 141, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2812', 139, 20, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2812', 142, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2815', 139, 20, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2815', 142, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2816', 141, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2826', 141, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2829', 141, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2830', 139, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2830', 141, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2832', 139, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2832', 141, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2833', 139, 20, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2833', 142, 10, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2834', 139, 40, CAST(0 AS Decimal(18, 0)))
INSERT [dbo].[OrderItems] ([ItemID], [OrderID], [Quntity], [Discount]) VALUES (N'2838', 141, 10, CAST(0 AS Decimal(18, 0)))
SET IDENTITY_INSERT [dbo].[Orders] ON 

INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (1, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FCB00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (2, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FF700000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (3, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A00700000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (4, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A0F200000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (5, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A11F00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (6, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A13A00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (7, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A27A00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (8, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A28700000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (9, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009CF100000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (10, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A0FF00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (11, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009E4700000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (12, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009E6000000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (13, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FC700000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (14, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FCB00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (15, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FF700000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (16, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A00700000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (17, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A0F200000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (18, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A11F00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (19, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A13A00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (20, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A27A00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (21, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A28700000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (22, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A2A600000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (24, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009CF500000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (25, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009D6E00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (26, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009DF900000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (27, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009E0500000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (28, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009E2200000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (29, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009E4700000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (30, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009E6100000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (31, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009E9100000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (32, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009F6400000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (33, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009F7200000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (34, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009F8E00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (35, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FAD00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (36, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FCB00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (37, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FEB00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (38, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A12200000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (39, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A2A700000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (40, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009CF600000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (41, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009E4700000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (42, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009E6300000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (43, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FC200000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (44, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A12200000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (45, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A13E00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (46, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A28700000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (47, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009CF400000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (48, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009E4700000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (49, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009E6200000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (50, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FC700000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (51, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FCB00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (52, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FEB00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (53, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A11F00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (54, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A13E00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (55, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A28100000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (56, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A28700000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (57, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A2AA00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (58, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009CF500000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (59, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009E3C00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (60, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009E4400000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (61, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009E6000000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (62, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FCB00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (63, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FEA00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (64, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A12200000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (65, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A28700000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (66, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A2AA00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (67, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009CF500000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (68, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009E3C00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (69, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009E3F00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (70, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009E6100000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (71, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FC700000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (72, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FCB00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (73, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FEA00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (74, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A0F200000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (75, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A12200000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (76, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A28100000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (77, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A28700000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (78, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009CF600000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (79, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009E3C00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (80, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009E3F00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (81, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009E6100000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (82, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FCB00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (83, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A0DA00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (84, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A11F00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (85, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A13A00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (86, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A28100000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (87, 3, 22033, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A28700000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (91, 3, 19884, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FEA00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (92, 3, 22036, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FEA00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (93, 3, 19889, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FF200000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (94, 3, 20019, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FF500000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (95, 3, 23007, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FF600000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (96, 3, 20202, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FF700000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (97, 3, 40526, N'', CAST(0 AS Decimal(18, 0)), CAST(0x00009FF900000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (98, 3, 22021, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A00000000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (99, 3, 22019, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A00000000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (100, 3, 22029, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A00700000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (101, 3, 22009, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A01D00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (102, 3, 22016, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A05200000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (103, 3, 20019, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A07400000000 AS DateTime))
GO
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (104, 3, 41101, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A07600000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (105, 3, 23469, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A07E00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (106, 3, 22029, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A08600000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (107, 3, 22063, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A09000000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (108, 3, 22030, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A09400000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (109, 3, 22025, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A09700000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (110, 3, 22022, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A09A00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (111, 3, 22003, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A09D00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (112, 3, 20940, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A0A100000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (113, 3, 22029, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A14C00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (114, 3, 22008, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A15D00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (115, 3, 22018, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A1B600000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (116, 3, 22040, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A1DC00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (117, 3, 22019, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A1E200000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (118, 3, 41101, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A1E800000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (119, 3, 23004, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A1ED00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (120, 3, 22042, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A1EE00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (121, 3, 20940, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A1EF00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (122, 3, 22015, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A1F000000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (123, 3, 22029, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A1F000000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (124, 3, 23461, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A1F100000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (125, 3, 22040, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A1F500000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (126, 3, 20940, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A1F500000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (128, 3, 22038, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A1F800000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (129, 3, 22029, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A1F800000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (130, 3, 22022, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A1F800000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (131, 3, 22063, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A1FF00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (133, 3, 23016, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A1FF00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (134, 3, 22003, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A20200000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (135, 3, 22063, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A21800000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (136, 3, 23003, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A21E00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (137, 3, 22008, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A24800000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (138, 3, 23469, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A28B00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (139, 3, 23004, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A2B300000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (140, 3, 23004, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A2AE00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (141, 3, 23004, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A29F00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (142, 3, 23004, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A29900000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (143, 3, 23004, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A28F00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (144, 3, 23004, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A28300000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (145, 3, 23004, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A26500000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (146, 3, 23004, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A25A00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (147, 3, 23004, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A21C00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (148, 3, 23004, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A20500000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (149, 3, 23004, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A14A00000000 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (1052, 3, 20940, N'', CAST(7 AS Decimal(18, 0)), CAST(0x0000A2B7013F0061 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (1053, 3, 20019, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A2B7013FADFF AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (1054, 3, 20202, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A2B7013FEE52 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (1055, 3, 19884, N'', CAST(7 AS Decimal(18, 0)), CAST(0x0000A2B70148EE69 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (1056, 3, 20019, N'', CAST(7 AS Decimal(18, 0)), CAST(0x0000A2B70149DF19 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (1057, 3, 20019, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A2B7014AA16B AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (1058, 3, 20940, N'', CAST(6 AS Decimal(18, 0)), CAST(0x0000A2B7014AFD9F AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (1059, 3, 20019, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A2B7014B1E4B AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (1060, 3, 22001, N'', CAST(7 AS Decimal(18, 0)), CAST(0x0000A2B7014C575D AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (1061, 3, 20202, N'', CAST(7 AS Decimal(18, 0)), CAST(0x0000A2B7014D324E AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (1062, 3, 20940, N'', CAST(7 AS Decimal(18, 0)), CAST(0x0000A2B7014D8B9A AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (1063, 3, 20940, N'', CAST(7 AS Decimal(18, 0)), CAST(0x0000A2B7014E7269 AS DateTime))
INSERT [dbo].[Orders] ([OrderID], [StatusID], [ClientID], [Comment], [Discount], [OrderDate]) VALUES (1064, 1, 20019, N'', CAST(0 AS Decimal(18, 0)), CAST(0x0000A2B7016D7FC1 AS DateTime))
SET IDENTITY_INSERT [dbo].[Orders] OFF
SET IDENTITY_INSERT [dbo].[OrderStatus] ON 

INSERT [dbo].[OrderStatus] ([StatusID], [StatusName]) VALUES (1, N'New')
INSERT [dbo].[OrderStatus] ([StatusID], [StatusName]) VALUES (2, N'Processing')
INSERT [dbo].[OrderStatus] ([StatusID], [StatusName]) VALUES (3, N'Succeeded')
INSERT [dbo].[OrderStatus] ([StatusID], [StatusName]) VALUES (4, N'Failed')
SET IDENTITY_INSERT [dbo].[OrderStatus] OFF
INSERT [dbo].[Roles] ([RoleId], [ApplicationId], [RoleName], [Description]) VALUES (N'0af3dc86-1754-46de-8949-1ccf2e8602eb', N'0f035459-682a-416b-8e0f-4aed8f3a2a34', N'Agent', NULL)
INSERT [dbo].[Roles] ([RoleId], [ApplicationId], [RoleName], [Description]) VALUES (N'46bb7405-dbc3-466f-9c2c-89fdaf97d0ae', N'0f035459-682a-416b-8e0f-4aed8f3a2a34', N'Administrator', NULL)
INSERT [dbo].[Roles] ([RoleId], [ApplicationId], [RoleName], [Description]) VALUES (N'230f452a-d42c-418f-a1cd-dc062ad4e24b', N'0f035459-682a-416b-8e0f-4aed8f3a2a34', N'Manager', NULL)
INSERT [dbo].[Users] ([UserId], [ApplicationId], [UserName], [IsAnonymous], [LastActivityDate]) VALUES (N'7d64d977-25d7-4e10-b719-35a66e5be9e2', N'0f035459-682a-416b-8e0f-4aed8f3a2a34', N'manager1', 0, CAST(0x0000A2950166724F AS DateTime))
INSERT [dbo].[Users] ([UserId], [ApplicationId], [UserName], [IsAnonymous], [LastActivityDate]) VALUES (N'ff44e525-d68c-47a8-81fd-5b2a752531f5', N'0f035459-682a-416b-8e0f-4aed8f3a2a34', N'admin', 0, CAST(0x0000A2B70132DDE4 AS DateTime))
INSERT [dbo].[Users] ([UserId], [ApplicationId], [UserName], [IsAnonymous], [LastActivityDate]) VALUES (N'3201f2fe-4370-49b5-a8de-9ff04a4249c6', N'0f035459-682a-416b-8e0f-4aed8f3a2a34', N'yossi', 0, CAST(0x0000A29501739405 AS DateTime))
INSERT [dbo].[Users] ([UserId], [ApplicationId], [UserName], [IsAnonymous], [LastActivityDate]) VALUES (N'2197afef-0362-4c7b-8784-be08477e3064', N'0f035459-682a-416b-8e0f-4aed8f3a2a34', N'may', 0, CAST(0x0000A2B700FD12E7 AS DateTime))
INSERT [dbo].[Users] ([UserId], [ApplicationId], [UserName], [IsAnonymous], [LastActivityDate]) VALUES (N'3dc5f705-7701-4859-9ecc-eb72d806e47b', N'0f035459-682a-416b-8e0f-4aed8f3a2a34', N'shani', 0, CAST(0x0000A29501667232 AS DateTime))
INSERT [dbo].[UsersInRoles] ([UserId], [RoleId]) VALUES (N'7d64d977-25d7-4e10-b719-35a66e5be9e2', N'230f452a-d42c-418f-a1cd-dc062ad4e24b')
INSERT [dbo].[UsersInRoles] ([UserId], [RoleId]) VALUES (N'ff44e525-d68c-47a8-81fd-5b2a752531f5', N'46bb7405-dbc3-466f-9c2c-89fdaf97d0ae')
INSERT [dbo].[UsersInRoles] ([UserId], [RoleId]) VALUES (N'3201f2fe-4370-49b5-a8de-9ff04a4249c6', N'0af3dc86-1754-46de-8949-1ccf2e8602eb')
INSERT [dbo].[UsersInRoles] ([UserId], [RoleId]) VALUES (N'2197afef-0362-4c7b-8784-be08477e3064', N'46bb7405-dbc3-466f-9c2c-89fdaf97d0ae')
INSERT [dbo].[UsersInRoles] ([UserId], [RoleId]) VALUES (N'3dc5f705-7701-4859-9ecc-eb72d806e47b', N'46bb7405-dbc3-466f-9c2c-89fdaf97d0ae')
SET ANSI_PADDING ON

GO
/****** Object:  Index [IDX_UserName]    Script Date: 18/01/2014 22:16:39 ******/
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
