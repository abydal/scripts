CREATE FUNCTION [dbo].[fnHashBytes] (@EncryptAlgorithm   NVARCHAR(4), @DataToEncrypt VARBINARY(MAX))
RETURNS   VARBINARY(MAX)
-- Author          : Arshad Ali
-- Create date     : 06/18/2014
-- Description     : It calculate MD5 for Large Objects by   splitting chunks of 8000 bytes to overcome HASHBYTES function limitation.
-- Parameters      :
--                                    1. EncryptAlgorithm   (NVARCHAR(4))    : It can be either MD2 or MD4 or MD5 or SHA or SHA1.
--                                    2. DataToEncrypt(VARBINARY(MAX))      : Plain text to encrypt, length of it will   be determined by the varbinary(max) data type size.
--                                    3. Return   Value(VARBINARY(MAX))     : If the encryption succeeded, it will   return the encrypted data or else will return NULL.
-- History      :  
-- ModifiedBy           ModifiedOn                        Remarks    
--
AS
BEGIN
        DECLARE @Index INTEGER
        DECLARE @DataToEncryptLength INTEGER
        DECLARE @EncryptedResult VARBINARY(MAX)
 
          IF @DataToEncrypt IS   NOT NULL
          BEGIN
                   SET @Index = 1
                   SET @DataToEncryptLength =   DATALENGTH(@DataToEncrypt)
                   WHILE @Index <=   @DataToEncryptLength
                   BEGIN
                             IF(@EncryptedResult   IS NULL )
                                          SET @EncryptedResult =   HASHBYTES(@EncryptAlgorithm, SUBSTRING(@DataToEncrypt,   @Index, 8000))
                             ELSE
                                          SET @EncryptedResult =   @EncryptedResult + HASHBYTES(@EncryptAlgorithm,   SUBSTRING(@DataToEncrypt, @Index, 8000))
                       
                             SET @Index = @Index   + 8000
                   END 
                   SET @EncryptedResult =   HASHBYTES(@EncryptAlgorithm, @EncryptedResult)
          END
          RETURN @EncryptedResult
END