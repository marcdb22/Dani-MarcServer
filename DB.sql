USE [master]
GO
/****** Object:  Database [PP_DDBB]    Script Date: 28/05/2025 13:51:03 ******/
CREATE DATABASE [PP_DDBB]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'PP_DDBB', FILENAME = N'/var/opt/mssql/data/PP_DDBB.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'PP_DDBB_log', FILENAME = N'/var/opt/mssql/data/PP_DDBB_log.ldf' , SIZE = 73728KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO
ALTER DATABASE [PP_DDBB] SET COMPATIBILITY_LEVEL = 160
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [PP_DDBB].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [PP_DDBB] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [PP_DDBB] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [PP_DDBB] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [PP_DDBB] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [PP_DDBB] SET ARITHABORT OFF 
GO
ALTER DATABASE [PP_DDBB] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [PP_DDBB] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [PP_DDBB] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [PP_DDBB] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [PP_DDBB] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [PP_DDBB] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [PP_DDBB] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [PP_DDBB] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [PP_DDBB] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [PP_DDBB] SET  ENABLE_BROKER 
GO
ALTER DATABASE [PP_DDBB] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [PP_DDBB] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [PP_DDBB] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [PP_DDBB] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [PP_DDBB] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [PP_DDBB] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [PP_DDBB] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [PP_DDBB] SET RECOVERY FULL 
GO
ALTER DATABASE [PP_DDBB] SET  MULTI_USER 
GO
ALTER DATABASE [PP_DDBB] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [PP_DDBB] SET DB_CHAINING OFF 
GO
ALTER DATABASE [PP_DDBB] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [PP_DDBB] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [PP_DDBB] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [PP_DDBB] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
EXEC sys.sp_db_vardecimal_storage_format N'PP_DDBB', N'ON'
GO
ALTER DATABASE [PP_DDBB] SET QUERY_STORE = ON
GO
ALTER DATABASE [PP_DDBB] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
USE [PP_DDBB]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_analyze_sql_inyection]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_analyze_sql_inyection] (
	@TEXT NVARCHAR(256)
)
RETURNS BIT
AS
BEGIN
    DECLARE @IsValid BIT;

    -- Verificar si la contraseña proporcionada coincide con la almacenada en la base de datos
	IF UPPER(@TEXT) LIKE '%SELECT%' OR @TEXT LIKE '%1=1%'
		SET @IsValid = 0;
	ELSE
		SET @IsValid = 1;

    RETURN @IsValid;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[fn_compare_passwords]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   FUNCTION [dbo].[fn_compare_passwords]
(
    @NEW_PASSWORD NVARCHAR(256),
    @USERNAME NVARCHAR(50)
)
RETURNS INT
AS
BEGIN
    DECLARE @pwd NVARCHAR(50);

    IF EXISTS (SELECT 1 FROM USERS WHERE USERNAME = @USERNAME)
    BEGIN
        SELECT @pwd = PASSWORD
        FROM USERS
        WHERE USERNAME = @USERNAME;

        -- Usando CASE para la comparaciÃ³n
        RETURN (
            SELECT CASE
                WHEN @NEW_PASSWORD IS NOT NULL AND @NEW_PASSWORD = @pwd THEN 1
                ELSE 0
            END
        );
    END
    ELSE
    BEGIN
        RETURN 0; -- El usuario no existe, asÃ­ que asumimos que la contraseÃ±a no es igual
    END

    -- Este return es redundante, pero se deja como salvaguarda
    RETURN -1;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[fn_compare_soundex]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   FUNCTION [dbo].[fn_compare_soundex] (
    @USERNAME NVARCHAR(25),
    @NEW_PASSWORD NVARCHAR(50)
)
RETURNS BIT
AS
BEGIN
    DECLARE @USER_ID INT;
    DECLARE @RESULT BIT = 1; -- 1 significa que no suena igual a las 3 Ãºltimas contraseÃ±as
    
    -- Obtener el ID del usuario
    SELECT @USER_ID = ID
    FROM USERS
    WHERE USERNAME = @USERNAME;

    -- Si el usuario no existe, retornar 1
    IF @USER_ID IS NULL
    BEGIN
        RETURN @RESULT;
    END

    -- Verificar las Ãºltimas 3 contraseÃ±as
    IF EXISTS (
        SELECT 1
        FROM (
            SELECT TOP 3 OLD_PASSWORD
            FROM PWD_HISTORY
            WHERE USER_ID = @USER_ID
            ORDER BY DATE_CHANGED DESC
        ) AS LastPasswords
        WHERE SOUNDEX(OLD_PASSWORD) = SOUNDEX(@NEW_PASSWORD)
    )
    BEGIN
        SET @RESULT = 0; -- 0 significa que suena igual a una de las 3 Ãºltimas contraseÃ±as
    END

    RETURN @RESULT;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[fn_generate_ssid]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   FUNCTION [dbo].[fn_generate_ssid]()
returns UNIQUEIDENTIFIER
AS
BEGIN
    declare @ssid UNIQUEIDENTIFIER;

    set @ssid = (select guid from v_guid)

    return @ssid
END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_mail_exists]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE   FUNCTION [dbo].[fn_mail_exists] (@EMAIL NVARCHAR(100))
RETURNS BIT
AS
BEGIN
    DECLARE @Exists BIT;
    SET @Exists = (
        SELECT CASE WHEN EXISTS (SELECT 1 FROM USERS WHERE EMAIL = @EMAIL) THEN 1 ELSE 0 END
    );
    RETURN @Exists;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[fn_mail_isvalid]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   FUNCTION [dbo].[fn_mail_isvalid] (@EMAIL NVARCHAR(100))
RETURNS BIT
AS
BEGIN
    DECLARE @ValidEmail BIT = 0;
    DECLARE @AtPosition INT, @DotPosition INT;

    -- Verificar si el correo electrÃ³nico contiene '@' y al menos un caracter antes y despuÃ©s
    SET @AtPosition = CHARINDEX('@', @EMAIL);
    IF (@AtPosition > 1 AND @AtPosition < LEN(@EMAIL))
    BEGIN
        -- Verificar si el correo electrÃ³nico contiene un punto despuÃ©s de '@' y al menos un caracter despuÃ©s del punto
        SET @DotPosition = CHARINDEX('.', @EMAIL, @AtPosition);
        IF (@DotPosition > (@AtPosition + 1) AND @DotPosition < LEN(@EMAIL))
        BEGIN
            SET @ValidEmail = 1;
        END;
    END;

    RETURN @ValidEmail;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[fn_pwd_checkpolicy]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- FunciÃ³n para verificar la polÃ­tica de contraseÃ±as
CREATE   FUNCTION [dbo].[fn_pwd_checkpolicy](@PASSWORD NVARCHAR(256))
RETURNS INT
AS
BEGIN
    DECLARE @errorPass BIT;
    SET @errorPass = 1;

    IF len(@PASSWORD) < 10
    BEGIN
        SET @errorPass = 0;
    END

    -- Verifica la existencia de un nÃºmero en la contraseÃ±a
    ELSE IF PATINDEX('%[0-9]%', @PASSWORD) = 0
    BEGIN
        SET @errorPass = 0;
    END

    -- Verifica la existencia de una letra en la contraseÃ±a
    ELSE IF PATINDEX('%[a-zA-Z]%', @PASSWORD) = 0
    BEGIN
        SET @errorPass = 0;
    END
    -- Verifica la existencia de un carÃ¡cter especial en la contraseÃ±a
    ELSE IF PATINDEX('%[^a-zA-Z0-9]%', @PASSWORD) = 0
    BEGIN
        SET @errorPass = 0;
    END

    RETURN @errorPass;
END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_pwd_isvalid]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- FunciÃ³n para verificar la contraseÃ±a del usuario
CREATE   FUNCTION [dbo].[fn_pwd_isvalid]
(
    @PASSWORD NVARCHAR(256),
    @USERNAME NVARCHAR(25)
)
RETURNS BIT
AS
BEGIN
    DECLARE @IsValid BIT;

    -- Verificar si la contraseÃ±a proporcionada coincide con la almacenada en la base de datos
    SET @IsValid = (
        SELECT CASE WHEN EXISTS (SELECT 1 FROM USERS WHERE USERNAME = @USERNAME AND PASSWORD = @PASSWORD) THEN 1 ELSE 0 END
    );

    RETURN @IsValid;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[fn_user_exists]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE   FUNCTION [dbo].[fn_user_exists] (@USERNAME NVARCHAR(25))
RETURNS BIT
AS
BEGIN
    DECLARE @Exists BIT;
    SET @Exists = (
        SELECT CASE WHEN EXISTS (SELECT 1 FROM USERS WHERE USERNAME = @USERNAME) THEN 1 ELSE 0 END
    );
    RETURN @Exists;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[fn_user_state]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   FUNCTION [dbo].[fn_user_state] 
(
    @USERNAME NVARCHAR(25)
)
RETURNS INT
AS
BEGIN
    DECLARE @userState INT;

    SELECT @userState = CASE WHEN u.STATUS = 1 THEN 1 ELSE 0 END
    FROM USERS u
    WHERE u.USERNAME = @USERNAME;

    RETURN @userState;
END;
GO
/****** Object:  View [dbo].[v_guid]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_guid] 
AS
    select newid() guid
GO
/****** Object:  Table [dbo].[BANK_ACCOUNTS]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BANK_ACCOUNTS](
	[ACCOUNT_ID] [uniqueidentifier] NOT NULL,
	[USER_ID] [int] NOT NULL,
	[USERNAME] [nvarchar](25) NOT NULL,
	[BALANCE] [decimal](18, 2) NULL,
	[CREATED_AT] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[ACCOUNT_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LANGUAGES]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LANGUAGES](
	[DEF_LANG] [nvarchar](3) NOT NULL,
	[LanguageName] [nvarchar](50) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[DEF_LANG] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PASSWORD_RESET_PIN]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PASSWORD_RESET_PIN](
	[USER_ID] [int] NOT NULL,
	[PIN] [char](6) NOT NULL,
	[CREATED_AT] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[USER_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PWD_HISTORY]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PWD_HISTORY](
	[HISTORY_ID] [int] IDENTITY(1,1) NOT NULL,
	[USER_ID] [int] NULL,
	[USERNAME] [nvarchar](25) NULL,
	[OLD_PASSWORD] [nvarchar](256) NULL,
	[DATE_CHANGED] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[HISTORY_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[STATUS]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[STATUS](
	[STATUS] [int] NOT NULL,
	[DESCRIPTION] [varchar](25) NULL,
PRIMARY KEY CLUSTERED 
(
	[STATUS] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[stored_hash]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[stored_hash](
	[PASSWORD] [nvarchar](256) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Transactions]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Transactions](
	[TransactionID] [int] IDENTITY(1,1) NOT NULL,
	[SenderID] [int] NOT NULL,
	[ReceiverID] [int] NOT NULL,
	[Amount] [decimal](18, 2) NOT NULL,
	[Timestamp] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[TransactionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[USER_CONNECTIONS]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[USER_CONNECTIONS](
	[CONNECTION_ID] [uniqueidentifier] NOT NULL,
	[USER_ID] [int] NULL,
	[USERNAME] [nvarchar](25) NULL,
	[DATE_CONNECTED] [datetime] NULL,
	[DATE_DISCONNECTED] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[CONNECTION_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[USER_CONNECTIONS_HISTORY]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[USER_CONNECTIONS_HISTORY](
	[HISTORY_ID] [int] IDENTITY(1,1) NOT NULL,
	[USER_ID] [int] NULL,
	[USERNAME] [nvarchar](30) NULL,
	[DATE_CONNECTED] [datetime] NULL,
	[DATE_DISCONNECTED] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[HISTORY_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[USER_ERRORS]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[USER_ERRORS](
	[ERROR_ID] [int] IDENTITY(0,1) NOT NULL,
	[ERROR_CODE] [int] NOT NULL,
	[ERROR_MESSAGE] [nvarchar](max) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ERROR_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[USERS]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[USERS](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[USERNAME] [nvarchar](25) NULL,
	[NAME] [nvarchar](25) NULL,
	[LASTNAME] [nvarchar](50) NULL,
	[PASSWORD] [nvarchar](256) NULL,
	[EMAIL] [nvarchar](100) NULL,
	[STATUS] [int] NULL,
	[GENDER] [nvarchar](1) NULL,
	[DEF_LANG] [nvarchar](3) NULL,
	[TIMESTAMP] [datetime] NULL,
	[REGISTER_CODE] [int] NULL,
	[LOGIN_STATUS] [bit] NULL,
	[ROL_USER] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[USERNAME] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[USER_ERRORS] ON 
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (-1, N'Error indefinido')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (0, N'¡El proceso a sido un éxito!')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (100, N'Usuario desconectado y registrado en el historial correctamente.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (402, N'La nueva contraseña no puede ser igual a la última contraseña.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (403, N'La nueva contraseña no puede sonar igual a las 3 últimas contraseñas.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (405, N'La conexión especificada no existe.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (408, N'El correo electrónico ya está registrado')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (409, N'El usuario ya existe')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (410, N'Género no valido.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (411, N'Idioma no valido.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (423, N'La cuenta del usuario está inactiva o bloqueada.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (450, N'El correo electrónico no cumple los requisitos')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (451, N'La contraseña no cumple los requisitos')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (500, N'El usuario se esta desconectando.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (501, N'El nombre de usuario no existe.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (502, N'La contraseña es incorrecta.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (503, N'La contraseña debe contener más de 10 caracteres, incluyendo al menos una mayúscula, una minúscula, un número y un carácter especial.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (504, N'No se encontraron conexiones activas.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (505, N'No se encontró historial de conexiones.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (506, N'No se encontraron usuarios con estado definido.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (507, N'No se encontró historial de conexiones para el usuario.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (508, N'No se encontraron errores.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (509, N'El email no esta registrado en la base de datos.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (600, N'Fondos insuficientes')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (700, N'El usuario especificado no existe.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (701, N'La cuenta del usuario ya está activada.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (702, N'El código de registro proporcionado no es válido.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (703, N'No se pudo actualizar el estado del usuario.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (704, N'Este email no tiene solicitud de restablecimiento de contraseña.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (705, N'PIN de restablecimiento de contraseña incorrecto.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (800, N'No tienes permisos de administrador.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (900, N'Usuario receptor no existe.')
GO
INSERT [dbo].[USER_ERRORS] ([ERROR_CODE], [ERROR_MESSAGE]) VALUES (901, N'No puedes enviarte un bizum a ti mismo.')
GO
SET IDENTITY_INSERT [dbo].[USER_ERRORS] OFF
GO
INSERT [dbo].[STATUS] ([STATUS], [DESCRIPTION]) VALUES (0, N'Pendiente')
GO
INSERT [dbo].[STATUS] ([STATUS], [DESCRIPTION]) VALUES (1, N'Activo')
GO
INSERT [dbo].[STATUS] ([STATUS], [DESCRIPTION]) VALUES (2, N'Bloqueado')
GO
INSERT [dbo].[LANGUAGES] ([DEF_LANG], [LanguageName]) VALUES (N'ARA', N'Arabic')
GO
INSERT [dbo].[LANGUAGES] ([DEF_LANG], [LanguageName]) VALUES (N'CHN', N'Chinese')
GO
INSERT [dbo].[LANGUAGES] ([DEF_LANG], [LanguageName]) VALUES (N'DEU', N'German')
GO
INSERT [dbo].[LANGUAGES] ([DEF_LANG], [LanguageName]) VALUES (N'ENG', N'English')
GO
INSERT [dbo].[LANGUAGES] ([DEF_LANG], [LanguageName]) VALUES (N'ESP', N'Spanish')
GO
INSERT [dbo].[LANGUAGES] ([DEF_LANG], [LanguageName]) VALUES (N'FRA', N'French')
GO
INSERT [dbo].[LANGUAGES] ([DEF_LANG], [LanguageName]) VALUES (N'ITA', N'Italian')
GO
INSERT [dbo].[LANGUAGES] ([DEF_LANG], [LanguageName]) VALUES (N'JPN', N'Japanese')
GO
INSERT [dbo].[LANGUAGES] ([DEF_LANG], [LanguageName]) VALUES (N'POR', N'Portuguese')
GO
INSERT [dbo].[LANGUAGES] ([DEF_LANG], [LanguageName]) VALUES (N'RUS', N'Russian')
GO
ALTER TABLE [dbo].[BANK_ACCOUNTS] ADD  DEFAULT (newid()) FOR [ACCOUNT_ID]
GO
ALTER TABLE [dbo].[BANK_ACCOUNTS] ADD  DEFAULT ((0)) FOR [BALANCE]
GO
ALTER TABLE [dbo].[BANK_ACCOUNTS] ADD  DEFAULT (CONVERT([datetime],switchoffset(sysdatetimeoffset(),'+02:00'))) FOR [CREATED_AT]
GO
ALTER TABLE [dbo].[PASSWORD_RESET_PIN] ADD  DEFAULT (CONVERT([datetime],switchoffset(sysdatetimeoffset(),'+02:00'))) FOR [CREATED_AT]
GO
ALTER TABLE [dbo].[PWD_HISTORY] ADD  DEFAULT (CONVERT([datetime],switchoffset(sysdatetimeoffset(),'+02:00'))) FOR [DATE_CHANGED]
GO
ALTER TABLE [dbo].[Transactions] ADD  DEFAULT (CONVERT([datetime],switchoffset(sysdatetimeoffset(),'+02:00'))) FOR [Timestamp]
GO
ALTER TABLE [dbo].[USER_CONNECTIONS] ADD  DEFAULT (CONVERT([datetime],switchoffset(sysdatetimeoffset(),'+02:00'))) FOR [DATE_CONNECTED]
GO
ALTER TABLE [dbo].[USER_CONNECTIONS_HISTORY] ADD  DEFAULT (CONVERT([datetime],switchoffset(sysdatetimeoffset(),'+02:00'))) FOR [DATE_CONNECTED]
GO
ALTER TABLE [dbo].[USER_CONNECTIONS_HISTORY] ADD  DEFAULT (CONVERT([datetime],switchoffset(sysdatetimeoffset(),'+02:00'))) FOR [DATE_DISCONNECTED]
GO
ALTER TABLE [dbo].[USERS] ADD  DEFAULT (CONVERT([datetime],switchoffset(sysdatetimeoffset(),'+02:00'))) FOR [TIMESTAMP]
GO
ALTER TABLE [dbo].[BANK_ACCOUNTS]  WITH CHECK ADD FOREIGN KEY([USER_ID])
REFERENCES [dbo].[USERS] ([ID])
GO
ALTER TABLE [dbo].[BANK_ACCOUNTS]  WITH CHECK ADD FOREIGN KEY([USERNAME])
REFERENCES [dbo].[USERS] ([USERNAME])
GO
ALTER TABLE [dbo].[PASSWORD_RESET_PIN]  WITH CHECK ADD FOREIGN KEY([USER_ID])
REFERENCES [dbo].[USERS] ([ID])
GO
ALTER TABLE [dbo].[PWD_HISTORY]  WITH CHECK ADD FOREIGN KEY([USER_ID])
REFERENCES [dbo].[USERS] ([ID])
GO
ALTER TABLE [dbo].[Transactions]  WITH CHECK ADD  CONSTRAINT [FK_Transactions_Receiver] FOREIGN KEY([ReceiverID])
REFERENCES [dbo].[USERS] ([ID])
GO
ALTER TABLE [dbo].[Transactions] CHECK CONSTRAINT [FK_Transactions_Receiver]
GO
ALTER TABLE [dbo].[Transactions]  WITH CHECK ADD  CONSTRAINT [FK_Transactions_Sender] FOREIGN KEY([SenderID])
REFERENCES [dbo].[USERS] ([ID])
GO
ALTER TABLE [dbo].[Transactions] CHECK CONSTRAINT [FK_Transactions_Sender]
GO
ALTER TABLE [dbo].[USER_CONNECTIONS]  WITH CHECK ADD FOREIGN KEY([USER_ID])
REFERENCES [dbo].[USERS] ([ID])
GO
ALTER TABLE [dbo].[USER_CONNECTIONS_HISTORY]  WITH CHECK ADD FOREIGN KEY([USER_ID])
REFERENCES [dbo].[USERS] ([ID])
GO
ALTER TABLE [dbo].[USERS]  WITH CHECK ADD FOREIGN KEY([DEF_LANG])
REFERENCES [dbo].[LANGUAGES] ([DEF_LANG])
GO
ALTER TABLE [dbo].[USERS]  WITH CHECK ADD FOREIGN KEY([STATUS])
REFERENCES [dbo].[STATUS] ([STATUS])
GO
/****** Object:  StoredProcedure [dbo].[getPasswordHash]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[getPasswordHash]
    @username VARCHAR(25)
AS
BEGIN
    DECLARE @stored_hash NVARCHAR(256);

    -- Obtener el hash de la base de datos
    SELECT @stored_hash = PASSWORD FROM users WHERE USERNAME = @username;

    -- Devolver el hash si el usuario existe
    IF @stored_hash IS NOT NULL 
        SELECT @stored_hash AS hashed_password;
    ELSE
        SELECT 'USER_NOT_FOUND' AS hashed_password;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_check_pwd]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_check_pwd] 
    @pwd NVARCHAR(255), 
    @score INT OUTPUT,
	@xml XML OUTPUT
AS
BEGIN
    DECLARE @text NVARCHAR(2000) = '';  -- Inicializar correctamente la variable de texto
    SET @pwd = @pwd COLLATE Latin1_General_CS_AS;
	SET @score = 0;
	SET @xml = '';

    -- Longitud mínima de 8 caracteres (+10 pts)
    IF LEN(@pwd) >= 8 
        SET @score = @score + 10;
    ELSE
        SET @text = @text + 'longitud mínima, ';
    
    -- Contiene al menos una mayúscula (+10 pts)
    IF @pwd LIKE '%[ABCDEFGHIJKLMNÑOPQRSTUVWXYZ]%' COLLATE Latin1_General_CS_AS  
        SET @score = @score + 10;
    ELSE
        SET @text = @text + 'mayúscula, ';

    -- Contiene al menos una minúscula (+10 pts)
    IF @pwd LIKE '%[abcdefghijklmnñopqrstuvwxyz]%' COLLATE Latin1_General_CS_AS  
        SET @score = @score + 10;
    ELSE
        SET @text = @text + 'minúscula, ';

    -- Contiene al menos un número (+10 pts)
    IF @pwd LIKE '%[0-9]%' COLLATE Latin1_General_CS_AS
        SET @score = @score + 10;
    ELSE
        SET @text = @text + 'número, ';

    -- Contiene al menos un carácter especial (+10 pts)
    IF @pwd LIKE '%[^a-zA-Z0-9]%' 
        SET @score = @score + 10;
    ELSE
        SET @text = @text + 'carácter especial, ';

    -- Eliminar la última coma y espacio si hay requisitos no cumplidos
    IF LEN(@text) > 0 
        SET @text = LEFT(@text, LEN(@text) - 1);
	
	-- Convertir a XML solo si hay requisitos no cumplidos
    IF LEN(@text) > 0
		SET @xml = (SELECT @text AS [text()] FOR XML PATH(''), TYPE);
	ELSE
		SET @xml = 'Ninguno';

END;
GO
/****** Object:  StoredProcedure [dbo].[sp_list_connections]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_list_connections]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ret INT;
    SET @ret = -1;

    DECLARE @XMLFlag XML;

    IF EXISTS (
        SELECT 1 FROM USER_CONNECTIONS -- Verifica la tabla correcta
    )
    BEGIN
        SET @XMLFlag = (
            SELECT * FROM USER_CONNECTIONS
            FOR XML PATH('Connection'), ROOT('Connections'), TYPE
        );
        SET @ret = 0;
    END
    ELSE
    BEGIN
        UPDATE USERS SET LOGIN_STATUS = 0;
        SET @ret = 504;
    END

    IF @ret <> 0
    BEGIN
        ExitProc:
        DECLARE @ResponseXML XML;
        EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;
        SELECT @ResponseXML;
    END
    ELSE
        SELECT @XMLFlag;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_list_errors]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_list_errors]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ret INT;
    SET @ret = -1;

    DECLARE @XMLFlag XML;

    -- Verificar si hay errores
    IF EXISTS (SELECT 1 FROM USER_ERRORS)
    BEGIN
        -- Si hay errores, convertir el conjunto de resultados a XML
        SET @XMLFlag = (
            SELECT * FROM USER_ERRORS
            FOR XML PATH('Errors'), ROOT('Errors'), TYPE
        );
        SET @ret = 0; -- Indicar que hubo resultados
    END
    ELSE
    BEGIN
        SET @ret = 508;
    END

    IF @ret <> 0
    BEGIN
        ExitProc:
        DECLARE @ResponseXML XML;
        EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;
        SELECT @ResponseXML;
    END
    ELSE
        SELECT @XMLFlag;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_list_historic_connections]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_list_historic_connections]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ret INT;
    SET @ret = -1;

    DECLARE @XMLFlag XML;

    -- Verificar si hay datos en el historial de conexiones
    IF EXISTS (SELECT 1 FROM USER_CONNECTIONS_HISTORY)
    BEGIN
        -- Si hay datos, convertir el conjunto de resultados a XML
        SET @XMLFlag = (
            SELECT HISTORY_ID,USERNAME,DATE_CONNECTED,DATE_DISCONNECTED FROM USER_CONNECTIONS_HISTORY
            FOR XML PATH('HistoricConnections'), ROOT('HistoricConnections'), TYPE
        );
        SET @ret = 0; -- Indicar que hubo resultados
    END
    ELSE
    BEGIN
        SET @ret = 505; -- Indicar que hubo resultados
    END
    
    IF @ret <> 0
    BEGIN
        ExitProc:
        DECLARE @ResponseXML XML;
        EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;
        SELECT @ResponseXML;
    END
    ELSE
        SELECT @XMLFlag;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_list_system_status]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_list_system_status]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ret INT;
    SET @ret = -1;

    DECLARE @XMLFlag XML;

    -- Verificar si hay usuarios con estado definido
    IF EXISTS (
        SELECT 1 FROM USERS u
        INNER JOIN STATUS s ON u.STATUS = s.STATUS
    )
    BEGIN
        -- Si hay usuarios con estado, convertir el conjunto de resultados a XML
        SET @XMLFlag = (
            SELECT u.ID AS UserID, u.USERNAME, s.STATUS
            FROM USERS u
            INNER JOIN STATUS s ON u.STATUS = s.STATUS
            FOR XML PATH(''), ROOT('SystemStatus'), TYPE
        );
        SET @ret = 0; -- Indicar que hubo resultados
    END
    ELSE
    BEGIN
        SET @ret = 506;
    END

    IF @ret <> 0
    BEGIN
        ExitProc:
        DECLARE @ResponseXML XML;
        EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;
        SELECT @ResponseXML;
    END
    ELSE
        SELECT @XMLFlag;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_list_users]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- Procedimiento almacenado para listar usuarios
CREATE   PROCEDURE [dbo].[sp_list_users]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ret INT;
    SET @ret = -1;

    DECLARE @XMLFlag XML;

    -- Verificar si hay datos en el historial de conexiones
    IF EXISTS (SELECT 1 FROM USERS)
    BEGIN
        -- Si hay datos, convertir el conjunto de resultados a XML
        SET @XMLFlag = (
            SELECT USERNAME FROM USERS
            FOR XML PATH('Usuarios'), ROOT('Usuarios'), TYPE
        );
    END
    ELSE
    BEGIN
        SET @ret = 505; -- Indicar que hubo resultados
    END
    
    IF @ret <> -1
    BEGIN
        ExitProc:
        DECLARE @ResponseXML XML;
        EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;
        SELECT @ResponseXML;
    END
    ELSE
        SELECT @XMLFlag;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_list_users2]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- Procedimiento almacenado para listar usuarios
CREATE   PROCEDURE [dbo].[sp_list_users2]
    @ssid NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ret INT;
    SET @ret = -1;

    DECLARE @XMLFlag XML;

    DECLARE @USERNAME NVARCHAR(250);

    DECLARE @ROL_USER BIT;
    
    SELECT @USERNAME=USERNAME
    FROM USER_CONNECTIONS
    WHERE CAST(CONNECTION_ID AS nvarchar(255))=@ssid ;

    SELECT @ROL_USER = ROL_USER
    FROM USERS
    WHERE USERNAME = @USERNAME;

    IF @ROL_USER = 1
    BEGIN
        -- Verificar si hay datos en el historial de conexiones
        IF EXISTS (SELECT 1 FROM USERS)
        BEGIN
            -- Si hay datos, convertir el conjunto de resultados a XML
            SET @XMLFlag = (
                SELECT USERNAME FROM USERS
                FOR XML PATH('Usuarios'), ROOT('Usuarios'), TYPE
            );
        END
        ELSE
        BEGIN
            SET @ret = 505; -- Indicar que NO hubo resultados
        END
    END
    ELSE
    BEGIN
        SET @ret = 800;
    END
    
    IF @ret <> -1
    BEGIN
        ExitProc:
        DECLARE @ResponseXML XML;
        EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;
        SELECT @ResponseXML;
    END
    ELSE
        SELECT @XMLFlag;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_uc_check_balance]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_uc_check_balance] 
    @SSID NVARCHAR(255)
AS
BEGIN
    DECLARE @ret INT = -1;
    DECLARE @USER_ID INT;
    DECLARE @DATE_CONNECTED DATETIME;
    DECLARE @BALANCE DECIMAL(18, 2);
	DECLARE @BALANCE_XML XML;

    EXEC sp_wdev_check_user_connection 
        @SSID = @SSID,
        @USER_ID = @USER_ID OUTPUT,
        @DATE_CONNECTED = @DATE_CONNECTED OUTPUT,
        @ret = @ret OUTPUT;

    IF @ret <> 100
    BEGIN
        SET @ret = 405; -- Conexión no válida
        GOTO ExitProc;
    END
	ELSE
	BEGIN
		SELECT @BALANCE = BALANCE FROM BANK_ACCOUNTS WHERE USER_ID = @USER_ID;
		SET @ret = 0;
	END

	ExitProc:
    DECLARE @ResponseXML XML, @Connection_ID_XML XML;
    EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT, @Action = 'check_balance';
	SET @Balance_XML = (
		SELECT @BALANCE FOR XML PATH('BALANCE')
	);
	SET @ResponseXML = (
		SELECT @ResponseXML, @Balance_XML
		FOR XML PATH ('root')
	);
    SELECT @ResponseXML;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_uc_check_username]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_uc_check_username] 
    @SSID NVARCHAR(255),
	@RECEIVER NVARCHAR(50)
AS
BEGIN
    DECLARE @SENDER_ID INT;
	DECLARE @RECEIVER_ID INT;

	SET @RECEIVER = @RECEIVER COLLATE Latin1_General_CS_AS;
	SET @SENDER_ID = (SELECT USER_ID FROM USER_CONNECTIONS WHERE CONNECTION_ID = @SSID);
	
	IF EXISTS (SELECT 1 FROM USERS WHERE USERNAME=@RECEIVER)
    BEGIN
		SET @RECEIVER_ID = (SELECT ID FROM USERS WHERE USERNAME=@RECEIVER);
		IF @RECEIVER_ID = @SENDER_ID
		BEGIN
			SELECT 2;
		END
		ELSE
		BEGIN
			SELECT 1;
		END
	END
	ELSE
	BEGIN
		SELECT 0;
	END
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_uc_get_last_user_transaction]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_uc_get_last_user_transaction]
    @SSID NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @USER_ID INT;
    DECLARE @DATE_CONNECTED DATETIME;
    DECLARE @ret INT = -1;

    -- Verificar la conexión y obtener USER_ID
    EXEC sp_wdev_check_user_connection
        @SSID = @SSID,
        @USER_ID = @USER_ID OUTPUT,
        @DATE_CONNECTED = @DATE_CONNECTED OUTPUT,
        @ret = @ret OUTPUT;

    IF @ret <> 100
    BEGIN
        -- Error de sesión
        DECLARE @XmlError XML;
        EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @XmlError OUTPUT, @Action = 'get_last_transaction';
        SELECT @XmlError;
        RETURN;
    END

    -- Verificar si hay transacciones
    IF NOT EXISTS (
        SELECT 1 FROM Transactions
        WHERE SenderID = @USER_ID OR ReceiverID = @USER_ID
    )
    BEGIN
        -- No hay transacciones
        SELECT
            'No transaction found' AS [Message],
            @USER_ID AS [UserID]
        FOR XML PATH('NoTransaction'), ROOT('LastTransaction');
        RETURN;
    END

    -- Obtener la transacción más reciente con usernames
    SELECT TOP 1
        T.TransactionID,
        SU.USERNAME AS Sender,
        RU.USERNAME AS Receiver,
        T.Amount,
        T.Timestamp
    FROM Transactions T
    INNER JOIN USERS SU ON T.SenderID = SU.ID
    INNER JOIN USERS RU ON T.ReceiverID = RU.ID
    WHERE T.SenderID = @USER_ID OR T.ReceiverID = @USER_ID
    ORDER BY T.Timestamp DESC
    FOR XML PATH('Transaction'), ROOT('LastTransaction');
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_uc_get_user_transactions]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_uc_get_user_transactions]
    @SSID NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @USER_ID INT;
    DECLARE @DATE_CONNECTED DATETIME;
    DECLARE @ret INT = -1;

    -- Verificar la conexión y obtener USER_ID
    EXEC sp_wdev_check_user_connection
        @SSID = @SSID,
        @USER_ID = @USER_ID OUTPUT,
        @DATE_CONNECTED = @DATE_CONNECTED OUTPUT,
        @ret = @ret OUTPUT;

    IF @ret <> 100
    BEGIN
        -- Error de sesión
        DECLARE @XmlError XML;
        EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @XmlError OUTPUT, @Action = 'get_last_transaction';
        SELECT @XmlError;
        RETURN;
    END

    -- Verificar si hay transacciones
    IF NOT EXISTS (
        SELECT 1 FROM Transactions
        WHERE SenderID = @USER_ID OR ReceiverID = @USER_ID
    )
    BEGIN
        -- No hay transacciones
        SELECT
            'No transaction found' AS [Message],
            @USER_ID AS [UserID]
        FOR XML PATH('NoTransaction'), ROOT('LastTransaction');
        RETURN;
    END

    -- Obtener la transacción más reciente con usernames
	DECLARE @XmlString NVARCHAR(MAX);

	SELECT @XmlString = CAST((
		SELECT T.TransactionID,
			SU.USERNAME AS Sender,
			RU.USERNAME AS Receiver,
			T.Amount,
			T.Timestamp
		FROM Transactions T
		INNER JOIN USERS SU ON T.SenderID = SU.ID
		INNER JOIN USERS RU ON T.ReceiverID = RU.ID
		WHERE T.SenderID = @USER_ID OR T.ReceiverID = @USER_ID
		ORDER BY T.Timestamp DESC
		FOR XML PATH('Transaction'), ROOT('Transactions')
	) AS NVARCHAR(MAX));

	SELECT @XmlString;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_uc_send_bizum]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_uc_send_bizum]
    @SSID NVARCHAR(255),
    @RECEIVER_USERNAME NVARCHAR(25),
    @AMOUNT DECIMAL(18, 2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ret INT = -1;
    DECLARE @SENDER_ID INT;
    DECLARE @RECEIVER_ID INT;
    DECLARE @SENDER_USERNAME NVARCHAR(25);
    DECLARE @DATE_CONNECTED DATETIME;
    DECLARE @SENDER_BALANCE DECIMAL(18, 2);
	DECLARE @TransactionID INT;

    -- Paso 1: Verificar la conexión mediante la procedure centralizada
    EXEC sp_wdev_check_user_connection 
        @SSID = @SSID,
        @USER_ID = @SENDER_ID OUTPUT,
        @DATE_CONNECTED = @DATE_CONNECTED OUTPUT,
        @ret = @ret OUTPUT;

    IF @ret <> 100
    BEGIN
        SET @ret = 405; -- Conexión no válida
        GOTO ExitProc;
    END
	ELSE
	BEGIN
		-- Paso 2: Verificar que el receptor exista o que sea el mismo
		SELECT @RECEIVER_ID = ID FROM USERS WHERE USERNAME = @RECEIVER_USERNAME;

		IF @RECEIVER_ID IS NULL
		BEGIN
			SET @ret = 900; -- Usuario receptor no existe
			GOTO ExitProc;
		END
		ELSE IF @SENDER_ID = @RECEIVER_ID
		BEGIN
			SET @ret = 901;
			GOTO ExitProc;
		END
		ELSE
		BEGIN
			-- Paso 3: Verificar fondos suficientes
			SELECT @SENDER_BALANCE = BALANCE FROM BANK_ACCOUNTS WHERE USER_ID = @SENDER_ID;

			IF @SENDER_BALANCE IS NULL OR @SENDER_BALANCE < @AMOUNT
			BEGIN
				SET @ret = 600; -- Fondos insuficientes
				GOTO ExitProc;
			END
			ELSE
			BEGIN

				-- Paso 4: Realizar la transacción
				INSERT INTO Transactions (SenderID, ReceiverID, Amount)
				VALUES (@SENDER_ID, @RECEIVER_ID, @AMOUNT);

				SET @TransactionID = SCOPE_IDENTITY();

				-- Paso 5: Actualizar saldos
				UPDATE BANK_ACCOUNTS
				SET BALANCE = BALANCE - @AMOUNT
				WHERE USER_ID = @SENDER_ID;

				UPDATE BANK_ACCOUNTS
				SET BALANCE = BALANCE + @AMOUNT
				WHERE USER_ID = @RECEIVER_ID;

				    -- Paso 6: Generar bloque para blockchain
				EXEC BlockchainDB.dbo.sp_blockchain_add_block 
					@TransactionID = @TransactionID,
					@SenderID = @SENDER_ID,
					@ReceiverID = @RECEIVER_ID,
					@Amount = @AMOUNT,
					@ret = @ret OUTPUT;

				SET @ret = 0;
			END
		END
	END

ExitProc:
    DECLARE @ResponseXML XML;
    EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT, @Action = 'send_bizum';
    SELECT @ResponseXML;
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_user_accountvalidate]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_user_accountvalidate]
    @USERNAME NVARCHAR(25),
    @REGISTER_CODE INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ret INT = -1;
    DECLARE @UserID INT;
    DECLARE @UserStatus INT;
    DECLARE @UserRegisterCode INT;

    -- Verificar si el usuario existe
    IF dbo.fn_user_exists(@USERNAME) = 0
    BEGIN
        SET @ret = 501;
        GOTO ExitProc;
    END;

    -- Obtener el ID, estado y register code del usuario
    SELECT @UserID = ID, @UserStatus = STATUS, @UserRegisterCode = REGISTER_CODE
    FROM USERS
    WHERE USERNAME = @USERNAME;

    -- Verificar si el usuario ya estÃ¡ activo
    IF @UserStatus = 1
    BEGIN
        SET @ret = 701;
        GOTO ExitProc;
    END;

    -- Verificar si el cÃ³digo de registro coincide
    IF @REGISTER_CODE <> @UserRegisterCode
    BEGIN
        SET @ret = 702;
        GOTO ExitProc;
    END;

    -- Actualizar el estado del usuario a activo (1)
    UPDATE USERS SET STATUS = 1 WHERE ID = @UserID;

    -- Verificar si se actualizÃ³ correctamente
    IF @@ROWCOUNT = 0
    BEGIN
        SET @ret = 703;
        GOTO ExitProc;
    END
    ELSE
    BEGIN
        SET @ret = 0;
        GOTO ExitProc;
    END;

ExitProc:
    DECLARE @ResponseXML XML;
    EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT, @Action = 'accvalidate';
    SELECT @ResponseXML;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_user_change_password]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- sp_user_change_password
CREATE   PROCEDURE [dbo].[sp_user_change_password]
    @SSID NVARCHAR(255), 
    @CURRENT_PASSWORD NVARCHAR(256), 
    @NEW_PASSWORD NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @USERNAME NVARCHAR(50);
    DECLARE @ret INT;
    SET @ret = -1;

	SET @USERNAME = (SELECT USERNAME FROM USERS WHERE ID = (
						SELECT USER_ID FROM USER_CONNECTIONS WHERE CONNECTION_ID = @SSID));

    -- Verifica que la contraseÃ±a actual sea vÃ¡lida
    IF (dbo.fn_pwd_isvalid(@CURRENT_PASSWORD, @USERNAME) = 0)
    BEGIN
        SET @ret = 502;
        GOTO ExitProc;
    END

    -- Verifica que la nueva contraseÃ±a cumpla con la polÃ­tica
    IF dbo.fn_pwd_checkpolicy(@NEW_PASSWORD) = 0
    BEGIN
        SET @ret = 503;
        GOTO ExitProc;
    END

    -- Verificar si la nueva contraseÃ±a es igual a alguna de las tres Ãºltimas contraseÃ±as
    IF dbo.fn_compare_soundex(@USERNAME, @NEW_PASSWORD) = 0
    BEGIN
        SET @ret = 402;
        GOTO ExitProc;
    END

    -- Verificar si la nueva contraseÃ±a es igual a la Ãºltima contraseÃ±a
    IF dbo.fn_compare_passwords(@NEW_PASSWORD, @USERNAME) = 1
    BEGIN
        SET @ret = 402;
        GOTO ExitProc;
    END

    -- Llamar a la procedure para actualizar la informaciÃ³n de contraseÃ±a del usuario
    EXEC sp_wdev_user_update_password_info @USERNAME, @CURRENT_PASSWORD, @NEW_PASSWORD, @ret OUTPUT;

    ExitProc:
    DECLARE @ResponseXML XML;
    EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT, @Action = "change_password";
    SELECT @ResponseXML;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_user_get_accountdata]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE   PROCEDURE [dbo].[sp_user_get_accountdata]
    @USERNAME NVARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ret INT;
    DECLARE @XMLFlag XML;

    SET @ret = -1;

    -- Llamar al procedimiento para verificar la existencia de datos
    EXEC sp_wdev_user_check_existence @USERNAME, @ret OUTPUT, @XMLFlag OUTPUT;

    IF @ret <> -1
    BEGIN
        DECLARE @ResponseXML XML;
        EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;
        SELECT @ResponseXML;
    END
    ELSE
        SELECT @XMLFlag;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_user_login]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_user_login]
    @USERNAME NVARCHAR(25),
    @PASSWORD NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @XML_RESPONSE XML;
    DECLARE @LOGIN_STATUS BIT;
    DECLARE @ret INT;
    SET @ret = -1;

    -- Verificar si el usuario estÃ¡ actualmente conectado
    EXEC sp_wdev_user_get_login_status @USERNAME, @LOGIN_STATUS OUTPUT, @ret OUTPUT;

    -- Verificar si el usuario existe
    IF (dbo.fn_user_exists(@USERNAME) = 0)
    BEGIN
        SET @ret = 501;
        GOTO ExitProc;
    END
    ELSE
    BEGIN
        -- Verificar el estado del usuario
        IF (dbo.fn_user_state(@USERNAME) = 0)
        BEGIN
            SET @ret = 423;
            GOTO ExitProc;
        END
        ELSE
        BEGIN
			 -- Verificar SQL Inyection
			IF (dbo.fn_analyze_sql_inyection(@PASSWORD) = 0)
			BEGIN
				SET @ret = 69	;
				GOTO ExitProc;
			END
			ELSE
			BEGIN
				-- Verificar la validez de la contraseÃ±a
				IF (dbo.fn_pwd_isvalid(@PASSWORD, @USERNAME) = 0)
				BEGIN
					SET @ret = 502;
					GOTO ExitProc;
				END
				ELSE
				BEGIN
					DECLARE @CONNECTION_ID UNIQUEIDENTIFIER;
					SET @CONNECTION_ID = dbo.fn_generate_ssid();

					-- Crear una nueva conexiÃ³n para el usuario
					EXEC sp_wdev_user_create_user_connection @USERNAME, @CONNECTION_ID, @ret OUTPUT;
				END
            END
        END
    END

    ExitProc:
    DECLARE @ResponseXML XML, @Connection_ID_XML XML;
    EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT, @Action = 'login';
	SET @Connection_ID_XML = (
		SELECT CONNECTION_ID FROM USER_CONNECTIONS WHERE USERNAME = @USERNAME
		FOR XML PATH('Connection_ID')
	);
	SET @ResponseXML = (
		SELECT @ResponseXML, @Connection_ID_XML
		FOR XML PATH ('root')
	);
    SELECT @ResponseXML;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_user_logout]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_user_logout]
    @SSID NVARCHAR(255) 
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ret INT;
	DECLARE @USERNAME NVARCHAR(25);
    DECLARE @USER_ID INT;
    DECLARE @DATE_CONNECTED DATETIME;
    DECLARE @DATE_DISCONNECTED DATETIME;

    SET @DATE_DISCONNECTED = SYSDATETIMEOFFSET() AT TIME ZONE 'Central European Standard Time';

    -- Comprueba si el usuario estÃ¡ conectado
    EXEC sp_wdev_check_user_connection @SSID, @USER_ID OUTPUT, @DATE_CONNECTED OUTPUT, @ret OUTPUT;

    IF @ret = 100
    BEGIN
		SET @USERNAME = (SELECT USERNAME FROM USERS WHERE ID = @USER_ID);
        -- Insertar en USER_CONNECTIONS_HISTORY antes de eliminar
        EXEC sp_wdev_insert_user_connection_history 
            @USER_ID, 
            @USERNAME, 
            @DATE_CONNECTED, 
            @DATE_DISCONNECTED -- fecha de desconexiÃ³n


        -- Eliminar de USER_CONNECTIONS
        DELETE FROM USER_CONNECTIONS WHERE CONNECTION_ID = @SSID;

        IF @@ROWCOUNT = 1
        BEGIN
            -- Actualizar estado de conexiÃ³n en USERS
            EXEC sp_wdev_update_user_login_status_0 @USERNAME;

            SET @ret = 0; -- Ã‰xito
        END
    END

    DECLARE @ResponseXML XML;
    EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT, @Action = 'logout';
    SELECT @ResponseXML;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_user_register]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE   PROCEDURE [dbo].[sp_user_register]
    @USERNAME NVARCHAR(25),
    @NAME NVARCHAR(25),
    @LASTNAME NVARCHAR(50),
    @PASSWORD NVARCHAR(256),
    @EMAIL NVARCHAR(30),
	@GENDER NVARCHAR(1),
	@DEF_LANG NVARCHAR(3)
AS 
BEGIN
    SET NOCOUNT ON;

    DECLARE @ret INT;
	DECLARE @result BIT;
	DECLARE @USER_ID INT;
    SET @ret = -1;

	-- Verificar SQL Inyection
	IF (dbo.fn_analyze_sql_inyection(@PASSWORD) = 0)
	BEGIN
		SET @ret = 69;
		GOTO ExitProc;
	END
	ELSE
	BEGIN
		-- Verificar si el usuario ya existe
		IF dbo.fn_user_exists(@USERNAME) = 1
		BEGIN
			SET @ret = 409;
			GOTO ExitProc;
		END
		ELSE
		BEGIN
			-- Verificar si el correo electrÃ³nico ya estÃ¡ registrado
			IF dbo.fn_mail_exists(@EMAIL) = 1
			BEGIN
				SET @ret = 408;
				GOTO ExitProc;
			END
			ELSE
			BEGIN
				-- Verificar si el correo electrÃ³nico es vÃ¡lido
				IF dbo.fn_mail_isvalid(@EMAIL) = 0
				BEGIN
					SET @ret = 450;
					GOTO ExitProc;
				END
				ELSE
				BEGIN
					-- Verificar la polÃ­tica de contraseÃ±a
					IF dbo.fn_pwd_checkpolicy(@PASSWORD) = 0
					BEGIN
						SET @ret = 451;
						GOTO ExitProc;
					END
					ELSE
					BEGIN
						-- Verificar el genero
						IF @GENDER NOT IN ('M', 'F', 'O')
						BEGIN
							SET @ret = 410;
							GOTO ExitProc;
						END
						ELSE
						BEGIN
							-- Verificar el idioma por defecto
							IF NOT EXISTS (SELECT 1 FROM LANGUAGES WHERE DEF_LANG = @DEF_LANG)
							BEGIN
								SET @ret = 411;
								GOTO ExitProc;
							END
							ELSE
							BEGIN
								-- Insertar el nuevo usuario si todas las validaciones son exitosas
								EXEC @ret = sp_wdev_user_insert @USERNAME, @NAME, @LASTNAME, @PASSWORD, @EMAIL, @GENDER, @DEF_LANG;

								IF @@ROWCOUNT > 0
								BEGIN
									-- Crear cuenta bancaria 
									SET @USER_ID = (SELECT ID FROM USERS WHERE USERNAME = @USERNAME);
									EXEC @result = dbo.sp_wdev_create_account @USER_ID, @USERNAME, 100;
									IF (@result = 1)
									BEGIN
										SET @ret = 0;  
										GOTO ExitProc;
									END
									ELSE
									BEGIN
										SET @ret = -1  
										GOTO ExitProc;
									END
								END
							END
						END
					END
				END
			END
		END
	END

    ExitProc:
    DECLARE @ResponseXML XML;
    EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT, @Action = 'register';
    SELECT @ResponseXML;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_check_user_connection]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE   PROCEDURE [dbo].[sp_wdev_check_user_connection]
    @SSID NVARCHAR(255),
    @USER_ID INT OUTPUT,
    @DATE_CONNECTED DATETIME OUTPUT,
    @ret INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @ret = -1;

    -- Comprueba si el usuario estÃ¡ conectado
    IF EXISTS (
        SELECT 1 FROM USER_CONNECTIONS WHERE CAST(CONNECTION_ID AS NVARCHAR(255)) = @SSID
    )
    BEGIN
        -- ObtÃ©n la informaciÃ³n de la conexiÃ³n
        SELECT 
            @USER_ID = USER_ID, 
            @DATE_CONNECTED = DATE_CONNECTED 
        FROM USER_CONNECTIONS 
        WHERE CAST(CONNECTION_ID AS NVARCHAR(255)) = @SSID;

        SET @ret = 100; -- Ã‰xito
    END
    ELSE
    BEGIN
        SET @ret = 405; -- ConexiÃ³n no encontrada
    END
END
GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_create_account]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_wdev_create_account]
	@USER_ID INT,
    @USERNAME NVARCHAR(25),
    @INITIAL_BALANCE DECIMAL(18,2) = 0
AS
BEGIN
    SET NOCOUNT ON;

    -- Crear la cuenta
    INSERT INTO BANK_ACCOUNTS (USER_ID, USERNAME, BALANCE, CREATED_AT)
    VALUES (@USER_ID, @USERNAME, @INITIAL_BALANCE, SWITCHOFFSET(SYSDATETIMEOFFSET(), '+02:00'));

    IF @@ROWCOUNT > 0
        RETURN 1; -- OK
    ELSE
        RETURN 0;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_deletealldata]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- sp_wdev_deletealldata
CREATE   PROCEDURE [dbo].[sp_wdev_deletealldata]
    @USERNAME NVARCHAR(25),
    @PASSWORD NVARCHAR(50)


AS
BEGIN
    DECLARE @ret INT;

    SET @ret= -1;

    
END
GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_get_registercode]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_wdev_get_registercode]
    @USERNAME NVARCHAR(25),
    @REGISTER_CODE INT OUTPUT -- ParÃ¡metro de salida para el cÃ³digo de registro
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ret INT;
    SET @ret = -1;

    -- Buscar el cÃ³digo de registro para el usuario dado
    SELECT @REGISTER_CODE = REGISTER_CODE
    FROM USERS
    WHERE USERNAME = @USERNAME;

    -- Verificar si se encontrÃ³ el cÃ³digo de registro
    IF @REGISTER_CODE IS NOT NULL
    BEGIN
        -- Si se encontrÃ³, establecer el cÃ³digo de retorno en 0 (Ã©xito)
        SET @ret = 0;
    END
    ELSE
    BEGIN
        -- Si no se encontrÃ³, establecer el cÃ³digo de retorno en 404 (no encontrado)
        SET @ret = 404;
    END

    -- Obtener el objeto XML de respuesta para el cÃ³digo de error
    DECLARE @ResponseXML XML;
    EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT, @Action = 'register_code';

    -- Verificar si se encontrÃ³ el cÃ³digo de registro
    IF @ret = 0
    BEGIN
        -- Si todo estÃ¡ bien, incluir el cÃ³digo de registro en el XML de respuesta
        SELECT @REGISTER_CODE;
    END

    -- Devolver el objeto XML de respuesta
    -- SELECT @ResponseXML;
END;




-- EXEC sp_get_registercode @USERNAME="pauallende04",@REGISTER_CODE=0
GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_insert_user_connection_history]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE   PROCEDURE [dbo].[sp_wdev_insert_user_connection_history]
    @USER_ID INT,
    @USERNAME NVARCHAR(25),
    @DATE_CONNECTED DATETIME,
    @DATE_DISCONNECTED DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO USER_CONNECTIONS_HISTORY (USER_ID, USERNAME, DATE_CONNECTED, DATE_DISCONNECTED)
    VALUES (@USER_ID, @USERNAME, @DATE_CONNECTED, @DATE_DISCONNECTED);
END
GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_recover_password_email]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_wdev_recover_password_email]
    @EMAIL NVARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @XML_RESPONSE XML;
    DECLARE @USER_ID INT;
    DECLARE @USERNAME NVARCHAR(25);
	DECLARE @RECOVERY_CODE INT;
	DECLARE @ret INT;
    SET @ret = -1;

    -- Verificar si el usuario existe
    IF (dbo.fn_mail_exists(@EMAIL) = 0)
    BEGIN
        SET @ret = 509;
        GOTO ExitProc;
    END
    ELSE
    BEGIN
		SET @RECOVERY_CODE = CAST((RAND() * 90000) + 10000 AS INT);
		SET @USER_ID = (SELECT ID FROM USERS WHERE EMAIL = @EMAIL);
		SET @USERNAME = (SELECT USERNAME FROM USERS WHERE EMAIL = @EMAIL);

		-- Insertar el PIN de recuperación
		IF NOT EXISTS (
			SELECT 1 FROM PASSWORD_RESET_PIN
			WHERE USER_ID = @USER_ID
		)
		BEGIN
			-- No hay transacciones
			INSERT INTO PASSWORD_RESET_PIN (USER_ID, PIN) VALUES (@USER_ID, @RECOVERY_CODE);
			SET @ret = 0;
		END
		ELSE
		BEGIN
			UPDATE PASSWORD_RESET_PIN SET PIN = @RECOVERY_CODE WHERE USER_ID = @USER_ID;
			SET @ret = 0;
		END
	END

	ExitProc:
    DECLARE @ResponseXML XML, @USERNAME_XML XML, @RECOVERY_CODE_XML XML;
    EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT, @Action = 'recover_password_email';
	SET @USERNAME_XML = (
		SELECT @USERNAME FOR XML PATH('USERNAME')
	);
	SET @RECOVERY_CODE_XML = (
		SELECT @RECOVERY_CODE FOR XML PATH('RECOVERY_CODE')
	);
	SET @ResponseXML = (
		SELECT @ResponseXML, @USERNAME_XML, @RECOVERY_CODE_XML
		FOR XML PATH ('root')
	);
    SELECT @ResponseXML;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_recover_password_pin]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_wdev_recover_password_pin]
    @EMAIL NVARCHAR(25),
	@PIN INT,
	@NEW_PASSWORD NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @XML_RESPONSE XML;
    DECLARE @USER_ID INT;
	DECLARE @USERNAME NVARCHAR(25);
	DECLARE @CURRENT_PASSWORD NVARCHAR(256);
	DECLARE @HPASSWORD NVARCHAR(256);
	DECLARE @ret INT;
    SET @ret = -1;

	-- Verificar SQL Inyection
	IF (dbo.fn_analyze_sql_inyection(@NEW_PASSWORD) = 0)
	BEGIN
		SET @ret = 69;
		GOTO ExitProc;
	END
	ELSE
	BEGIN
		-- Verificar si el usuario existe
		IF (dbo.fn_mail_exists(@EMAIL) = 0)
		BEGIN
			SET @ret = 509;
			GOTO ExitProc;
		END
		ELSE
		BEGIN
			SET @USER_ID = (SELECT ID FROM USERS WHERE EMAIL = @EMAIL);
			SET @USERNAME = (SELECT USERNAME FROM USERS WHERE EMAIL = @EMAIL);

			-- Insertar el PIN de recuperación
			IF NOT EXISTS (
				SELECT 1 FROM PASSWORD_RESET_PIN WHERE USER_ID = @USER_ID
			)
			BEGIN
				SET @ret = 704;
				GOTO ExitProc;
			END
			ELSE
			BEGIN
				IF @PIN != (SELECT PIN FROM PASSWORD_RESET_PIN WHERE USER_ID = @USER_ID)
				BEGIN
					SET @ret = 705;
					GOTO ExitProc;
				END
				ELSE
				BEGIN
					SET @HPASSWORD = LOWER(CONVERT(VARCHAR(256), HASHBYTES('MD5', CAST(@NEW_PASSWORD AS VARCHAR(256))), 2));
					-- Verifica que la nueva contraseÃ±a cumpla con la polÃ­tica
					IF dbo.fn_pwd_checkpolicy(@NEW_PASSWORD) = 0
					BEGIN
						SET @ret = 503;
						GOTO ExitProc;
					END

					-- Verificar si la nueva contraseÃ±a es igual a alguna de las tres Ãºltimas contraseÃ±as
					IF dbo.fn_compare_soundex(@USERNAME, @HPASSWORD) = 0
					BEGIN
						SET @ret = 402;
						GOTO ExitProc;
					END

					IF dbo.fn_compare_passwords(@HPASSWORD, @USERNAME) = 1
					BEGIN
						SET @ret = 402;
						GOTO ExitProc;
					END
					
					SET @CURRENT_PASSWORD = (SELECT PASSWORD FROM USERS WHERE ID = @USER_ID);
					EXEC sp_wdev_user_update_password_info @USERNAME, @CURRENT_PASSWORD, @HPASSWORD, @ret OUTPUT;
					DELETE FROM PASSWORD_RESET_PIN WHERE USER_ID = @USER_ID;
				END
			END
		END
	END

	ExitProc:
    DECLARE @ResponseXML XML, @USERNAME_XML XML, @RECOVERY_CODE_XML XML;
    EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT, @Action = 'recover_password_pin';
    SELECT @ResponseXML;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_update_user_login_status_0]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_wdev_update_user_login_status_0]
    @USERNAME NVARCHAR(25)
AS 
BEGIN
    UPDATE USERS SET LOGIN_STATUS = 0 WHERE USERNAME = @USERNAME;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_user_check_existence]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_wdev_user_check_existence]
    @USERNAME NVARCHAR(25),
    @ret INT OUTPUT,
    @XMLFlag XML OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verificar si hay datos en el historial de conexiones
    IF EXISTS (SELECT 1 FROM USERS WHERE USERNAME=@USERNAME)
    BEGIN
        -- Si hay datos, convertir el conjunto de resultados a XML
        SET @XMLFlag = (
            SELECT USERNAME, NAME, LASTNAME, EMAIL, GENDER FROM USERS WHERE USERNAME = @USERNAME
            FOR XML PATH('User'), ROOT('Users'), TYPE
        );

        SET @ret=0
    END
    ELSE
    BEGIN
        SET @ret = 505; -- Indicar que hubo resultados
    END
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_user_create_user_connection]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_wdev_user_create_user_connection]
    @USERNAME NVARCHAR(25),
    @CONNECTION_ID UNIQUEIDENTIFIER,
    @ret INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO USER_CONNECTIONS
        (CONNECTION_ID, USER_ID, USERNAME, DATE_CONNECTED)
    VALUES
        (@CONNECTION_ID, (SELECT ID FROM USERS WHERE USERNAME = @USERNAME), @USERNAME, CONVERT(DATETIME, SWITCHOFFSET(SYSDATETIMEOFFSET(), '+01:00')));

    UPDATE USERS SET LOGIN_STATUS = 1 WHERE USERNAME = @USERNAME;

    IF @@ROWCOUNT = 1
    BEGIN
        SET @ret = 0;
    END
    ELSE
    BEGIN
        SET @ret = -1; -- Algo saliÃ³ mal durante la creaciÃ³n de la conexiÃ³n
    END
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_user_get_login_status]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_wdev_user_get_login_status]
    @USERNAME NVARCHAR(25),
    @LOGIN_STATUS BIT OUTPUT,
    @ret INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @LOGIN_STATUS = LOGIN_STATUS
    FROM USERS
    WHERE USERNAME = @USERNAME;

    IF @LOGIN_STATUS = 1
    BEGIN
        SET @ret = 500;
    END
    ELSE
    BEGIN
        SET @ret = 0;
    END
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_user_insert]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE   PROCEDURE [dbo].[sp_wdev_user_insert]
@USERNAME NVARCHAR(25),
@NAME NVARCHAR(25),
@LASTNAME NVARCHAR(50),
@PASSWORD NVARCHAR(256),
@EMAIL NVARCHAR(30),
@GENDER NVARCHAR(1),
@DEF_LANG NVARCHAR(3)
AS
BEGIN
DECLARE @REGISTER_CODE INT;

    -- Generar cÃ³digo de 5 dÃ­gitos aleatorio
    SET @REGISTER_CODE = CAST((RAND() * 90000) + 10000 AS INT);

	DECLARE @HashedPWD VARCHAR(256);
	SET @HashedPWD = LOWER(CONVERT(VARCHAR(256), HASHBYTES('MD5', CAST(@PASSWORD AS VARCHAR(256))), 2));

    -- Insertar datos en la tabla USERS
    INSERT INTO USERS (USERNAME, NAME, LASTNAME, PASSWORD, EMAIL, STATUS, GENDER, DEF_LANG, REGISTER_CODE, LOGIN_STATUS, ROL_USER)
    VALUES (@USERNAME, @NAME, @LASTNAME, @HashedPWD, @EMAIL, 0, @GENDER, @DEF_LANG, @REGISTER_CODE, 0, 0);

    -- Devolver el cÃ³digo generado
    RETURN @REGISTER_CODE;

END;
GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_user_update_password_info]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_wdev_user_update_password_info]
    @USERNAME NVARCHAR(50),
    @CURRENT_PASSWORD NVARCHAR(256),
    @NEW_PASSWORD NVARCHAR(256),
    @ret INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @USER_ID INT;

    -- Obtener la informaciÃ³n del usuario
    SELECT 
        @USER_ID = ID
    FROM USERS 
    WHERE USERNAME = @USERNAME;

    -- Guardar la contraseÃ±a anterior en PWD_HISTORY
    INSERT INTO PWD_HISTORY(
        USER_ID,
        USERNAME,
        OLD_PASSWORD, 
        DATE_CHANGED
    ) 
    VALUES (
        @USER_ID,
        @USERNAME, 
        @CURRENT_PASSWORD, 
        CONVERT([datetime],switchoffset(sysdatetimeoffset(),'+02:00')) -- fecha de cambio de contraseÃ±a
    );

    -- Actualizar la contraseÃ±a del usuario
    UPDATE USERS 
    SET PASSWORD = @NEW_PASSWORD 
    WHERE USERNAME = @USERNAME;
    
    SET @ret = 0;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_xml_error_message]    Script Date: 28/05/2025 13:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_xml_error_message]
    @RETURN INT,
    @XmlResponse XML OUTPUT,
	@Action NVARCHAR (32)
AS
BEGIN
    DECLARE @ERROR_CODE INT;
    SET @ERROR_CODE = @RETURN;

    DECLARE @ERROR_MESSAGE NVARCHAR(200);
    DECLARE @CURRENT_TIME DATETIME = CONVERT([datetime],SWITCHOFFSET(SYSDATETIMEOFFSET(),'+02:00'));
    DECLARE @SERVER_ID NVARCHAR(50) = @@SERVERNAME;
    DECLARE @EXECUTION_TIME NVARCHAR(50) = CAST(DATEDIFF(MILLISECOND, @CURRENT_TIME, CONVERT([datetime],SWITCHOFFSET(SYSDATETIMEOFFSET(),'+02:00'))) AS NVARCHAR(50)) + ' ms';
    DECLARE @URL NVARCHAR(100) = 'www.ws.mybizum.com';
    DECLARE @METHOD_NAME NVARCHAR(50) = @Action;

    -- Recupera el mensaje de error de la tabla USER_ERRORS
    SELECT @ERROR_MESSAGE = ERROR_MESSAGE
    FROM USER_ERRORS
    WHERE ERROR_CODE = @ERROR_CODE;

    -- Construcción del XML según el modelo proporcionado
    SET @XmlResponse = (
        SELECT
            -- Sección <head>
            (
                SELECT
                    @SERVER_ID AS 'server_id',
                    CONVERT(NVARCHAR(20), @CURRENT_TIME, 120) AS 'server_time',
                    @EXECUTION_TIME AS 'execution_time',
                    @URL AS 'url',
                    (
                        SELECT
                            @METHOD_NAME AS 'name',
                            (
                                SELECT
                                    'RETURN' AS 'name',
                                    @ERROR_CODE AS 'value'
                                FOR XML PATH('parameter'), TYPE
                            ) AS 'parameters'
                        FOR XML PATH('webmethod'), TYPE
                    ),
                    (
                        -- Sección <errors> (si hay error o no)
                        SELECT
                            @ERROR_CODE AS 'num_error',
                            @ERROR_MESSAGE AS 'message_error',
                            CASE
                                WHEN @ERROR_CODE = 0 THEN 'INFO'
                                ELSE 'ERROR'
                            END AS 'severity',
                            @ERROR_MESSAGE AS 'user_message'
                        FOR XML PATH('error'), TYPE
                    ) AS 'errors'
                FOR XML PATH('head'), TYPE
            ),
            -- Sección <body>
            (
                SELECT
                    CASE
                        WHEN @ERROR_CODE = 0 THEN 'Operation completed successfully'
                        ELSE 'Operation failed'
                    END AS 'response_data'
                FOR XML PATH('body'), TYPE
            )
        FOR XML PATH('ws_response'), TYPE
    );

END
GO
USE [master]
GO
ALTER DATABASE [PP_DDBB] SET  READ_WRITE 
GO