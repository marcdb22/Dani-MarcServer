ALTER PROCEDURE [dbo].[sp_uc_get_user_transactions]
    @SSID NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @USER_ID INT;
    DECLARE @DATE_CONNECTED DATETIME;
    DECLARE @ret INT = -1;

    -- Verificar la conexión
    EXEC sp_wdev_check_user_connection
        @SSID = @SSID,
        @USER_ID = @USER_ID OUTPUT,
        @DATE_CONNECTED = @DATE_CONNECTED OUTPUT,
        @ret = @ret OUTPUT;

    IF @ret <> 100
        GOTO ExitProc;

    DECLARE @TransactionsXML XML;

    SELECT @TransactionsXML =
    (
        SELECT
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
        FOR XML PATH('Transaction'), ROOT('Transactions')
    );

 
    SELECT
        (
            SELECT
                '90f7019b87b3' AS server_id,
                GETDATE() AS server_time,
                '0 ms' AS execution_time,
                'www.ws.mybizum.com' AS url,
                (
                    SELECT
                        'get_user_transactions' AS name,
                        (
                            SELECT
                                'USER_ID' AS name,
                                @USER_ID AS value
                            FOR XML PATH('parameter'), ROOT('parameters'), TYPE
                        )
                    FOR XML PATH('webmethod'), TYPE
                ),
                (
                    SELECT
                        0 AS num_error,
                        'INFO' AS severity
                    FOR XML PATH('error'), ROOT('errors'), TYPE
                )
            FOR XML PATH('head'), TYPE
        ),
        (
            SELECT @TransactionsXML AS [response_data]
            FOR XML PATH('body'), TYPE
        )
    FOR XML PATH('ws_response');

    RETURN;


ExitProc:
    DECLARE @ResponseXML XML;
    EXEC sp_xml_error_message 
        @RETURN = @ret, 
        @XmlResponse = @ResponseXML OUTPUT, 
        @Action = 'get_user_transactions';

    SELECT @ResponseXML;
END;
GO


ALTER PROCEDURE [dbo].[sp_xml_error_message]
    @RETURN INT,
    @XmlResponse NVARCHAR(MAX) OUTPUT,
    @Action NVARCHAR(255),
    @CustomXML XML = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @CustomXML IS NULL
        SET @CustomXML = '<response_data>Operation completed successfully</response_data>';

    SET @XmlResponse = (
        SELECT
            (
                SELECT
                    '90f7019b87b3' AS server_id,
                    GETDATE() AS server_time,
                    '0 ms' AS execution_time,
                    'www.ws.mybizum.com' AS url,
                    (
                        SELECT
                            @Action AS name,
                            (
                                SELECT
                                    'RETURN' AS name,
                                    @RETURN AS value
                                FOR XML PATH('parameter'), ROOT('parameters'), TYPE
                            )
                        FOR XML PATH('webmethod'), TYPE
                    ),
                    (
                        SELECT
                            @RETURN AS num_error,
                            CASE WHEN @RETURN = 0 THEN 'INFO' ELSE 'ERROR' END AS severity
                        FOR XML PATH('error'), ROOT('errors'), TYPE
                    )
                FOR XML PATH('head'), TYPE
            ),
            (
                SELECT @CustomXML
                FOR XML PATH('body'), TYPE
            )
        FOR XML PATH('ws_response')
    );
END;
GO


SELECT @ret;
