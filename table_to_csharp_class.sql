DECLARE @TABLE_NAME nvarchar(MAX) =  'PRODUTO';
DECLARE @CLASS_NAME  nvarchar(MAX) = 'PRODUTO';
DECLARE @PREFIX nvarchar(10) = 'PRO_';

SET NOCOUNT ON
SELECT '[Table("'+ @TABLE_NAME + '")]' + CHAR(13) + 
		'public class ' + @CLASS_NAME + '{' + CHAR(13)
UNION ALL
SELECT	
			concat('[Column("',COLUMN_NAME,'")] ' + CHAR(13),
			  'public ', 
			  case DATA_TYPE
				when 'nvarchar' then 'string' 
				when 'varchar' then 'string'
				when 'datetime' then 'DateTime'
				when 'money' then 'decimal' 
				else DATA_TYPE
			  end,
			  case IS_NULLABLE
				when 'YES'	then '?'
				else ''
			  end,
			  ' ', 
			  REPLACE(COLUMN_NAME, @PREFIX, ''), 
			  '{get; set; }', CHAR(13)
			  )
	FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = @TABLE_NAME
union all
select '}';



