DROP PROCEDURE IF EXISTS dbo.sp_block_user;
GO


CREATE PROCEDURE [dbo].[sp_block_user]
    @SSID NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;


    DECLARE @ret INT = -1;


    UPDATE USERS
    SET STATUS = -1
    WHERE SSID = @SSID;


    IF @@ROWCOUNT = 0
        SET @ret = 501;
    ELSE
        SET @ret = 0;


    DECLARE @ResponseXML XML;


    EXEC sp_xml_error_message
        @RETURN = @ret,
        @XmlResponse = @ResponseXML OUTPUT,
        @Action = 'sp_block_user';


    SELECT @ResponseXML;
END;
GO


select * from USERS ;
select * from [STATUS];
