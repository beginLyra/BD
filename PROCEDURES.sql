CREATE PROCEDURE [exampleprep].[generate_activation_code]
    @Email NVARCHAR(255),
    @Code INT
AS
BEGIN
  

    DECLARE @n INT;

    -- Verifica si existe el usuario en la tabla [users]
    SELECT @n = COUNT(*) 
    FROM [exampleprep].[users] 
    WHERE [email] = @Email;

    -- Si el usuario existe, inserta el código de activación
    IF @n > 0
    BEGIN
        INSERT INTO [exampleprep].[activation_codes] ([email], [code])
        VALUES (@Email, @Code);
    END;

    -- Retorna un valor de control (opcional)
    SELECT 1 AS Completed;

END;




CREATE PROCEDURE [exampleprep].GetRecentActivationCodeWithTimeElapsed
    @Email VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    -- Declarar variables
    DECLARE @Code INT;
    DECLARE @CreatedAt DATETIME;
    DECLARE @CurrentDate DATETIME = GETDATE();

    -- Seleccionar el código más reciente y su fecha de creación
    SELECT TOP 1 
        @Code = code, 
        @CreatedAt = created_at
    FROM [exampleprep].[activation_codes]
    WHERE email = @Email
    ORDER BY created_at DESC;

    -- Si se encontró un código
    IF @Code IS NOT NULL
    BEGIN
        -- Calcular la diferencia de tiempo
        DECLARE @MinutesElapsed INT = DATEDIFF(MINUTE, @CreatedAt, @CurrentDate);
        DECLARE @SecondsElapsed INT = DATEDIFF(SECOND, @CreatedAt, @CurrentDate) % 60;

        -- Retornar el resultado
        SELECT 
            @Code AS ActivationCode,
            FORMAT(@CreatedAt, 'yyyy-MM-dd HH:mm:ss') AS CreatedAt,
            CONCAT('Usted activó el código hace ', @MinutesElapsed, ' minutos y ', @SecondsElapsed, ' segundos.') AS Message;
    END
    ELSE
    BEGIN
        SELECT 'No se encontraron códigos asociados a este correo.' AS Message;
    END
END;


CREATE PROCEDURE [exampleprep].VerifyAndActivateUser_Test
    @Email VARCHAR(255),
    @Code INT
AS
BEGIN
    DECLARE @CurrentDate DATETIME = GETDATE();
    DECLARE @ExpiredAt DATETIME;

    -- Verificar si el código existe para el correo proporcionado
    IF EXISTS (
        SELECT 1
        FROM [exampleprep].[activation_codes]
        WHERE email = @Email
          AND code = @Code
    )
    BEGIN
        -- Obtener la fecha de expiración del código
        SELECT @ExpiredAt = expired_at
        FROM [exampleprep].[activation_codes]
        WHERE email = @Email
          AND code = @Code;

        -- Verificar si el código ha expirado
        IF @ExpiredAt > @CurrentDate
        BEGIN
            -- Si el código no ha expirado, realizar el UPDATE
            UPDATE [exampleprep].[users]
            SET active = '1'
            WHERE email = @Email;

            SELECT 'Cuenta verificada' AS Message;
        END
        ELSE
        BEGIN
            -- Si el código ha expirado
            SELECT 'Código expirado' AS Message;
        END
    END
    ELSE
    BEGIN
        -- Si el código no existe para el correo proporcionado
        SELECT 'Código o correo no existentes' AS Message;
    END
END;