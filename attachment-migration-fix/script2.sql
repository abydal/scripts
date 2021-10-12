UPDATE Attachments SET ContentId=dbo.fnHashBytes('MD5', ac.bytes)
FROM Attachments a 
INNER JOIN AttachmentContents ac ON ac.Id=a.id
WHERE a.ContentId IS NULL OR LTRIM(RTRIM(a.ContentId)) =  '' AND ac.Bytes IS NOT NULL