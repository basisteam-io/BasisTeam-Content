-- ***** POST INSTALLATION STEPS FOR MICROSOFT SQL SERVER 2017 *****
-- EnableAutoGrowAllFiles
DBCC TRACEON (1117, -1)
-- EnableAutoUpdateStatistics
DBCC TRACEON (2371, -1)
-- EnableFullExtentsOnly
DBCC TRACEON (1118, -1)
-- If Number of cores not equivalent Number of files
-- Check. MS SQL Studio -> connect to DB -> tempdb -> Files
SELECT os.Cores, df.Files
FROM
(SELECT COUNT(*) AS Cores FROM sys.dm_os_schedulers WHERE status = 'VISIBLE ONLINE') AS os,
  (SELECT COUNT(*) AS Files FROM tempdb.sys.database_files WHERE type_desc = 'ROWS') AS df;