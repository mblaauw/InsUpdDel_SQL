--------------------------------------------------------------------------------------
-- SET DATABASE TO EXECUTE ON
--------------------------------------------------------------------------------------
USE MasterData_Dev

--------------------------------------------------------------------------------------
-- INIT Vars
--------------------------------------------------------------------------------------
DECLARE @BATCH_ID INT
DECLARE @NEW_BATCH_ID INT

--------------------------------------------------------------------------------------
-- MAIN LOOP
--------------------------------------------------------------------------------------
SET @BATCH_ID = (SELECT MAX(BatchID) FROM Compare)
-- FIRST BATCH, create initial load
IF @BATCH_ID IS NULL
	BEGIN 
		SET @BATCH_ID = 0
		INSERT INTO [dbo].[Compare]
		(BatchID, Id, F1, F2, F3, UPD, INS, DEL)
		SELECT @BATCH_ID, Id, F1, F2, F3, GETDATE(), GETDATE(), CONVERT(DATE, '1900-01-01') FROM [dbo].[Master]
	END
-- Secondary BATCHES Continue here
ELSE
	BEGIN 
		-- Add new row to batch
		SET @NEW_BATCH_ID = @BATCH_ID + 1

		-- Old batch to compare against
		SELECT Id, F1, F2, F3, UPD, INS, DEL 
		into #old_batch from [dbo].[Compare] WHERE [BatchID] = @BATCH_ID
		-- New batch into a temp table
		SELECT Id, F1, F2, F3, CONVERT(DATE, '1900-01-01') as UPD, CONVERT(DATE, '1900-01-01') as INS, CONVERT(DATE, '1900-01-01') as DEL
		into #new_batch from [dbo].[Master] 

		--------------------------------------------------------------------------------------
		-- Synch UPD and INS dates in new_batch based on stamps in old_batch
		--------------------------------------------------------------------------------------
		UPDATE newset
		SET newset.UPD = oldset.UPD, newset.INS = oldset.INS, newset.DEL = oldset.DEL 
		FROM #old_batch oldset
		INNER JOIN #new_batch newset
		ON oldset.Id = newset.Id

		--------------------------------------------------------------------------------------
		-- Find and UPDATE new records in NEW_BATCH
		--------------------------------------------------------------------------------------
		Select * 
		INTO #NewInBatch
		FROM (
		SELECT ID FROM #new_batch 
		EXCEPT
		SELECT ID FROM #old_batch
		) as NewInNewBatch
		-- UPDATE INSERT FLAG and UPDATE flag since its first record it is technically also an UPDATE
		UPDATE #new_batch
		SET #new_batch.INS = GETDATE(), #new_batch.UPD =GETDATE()
		WHERE #new_batch.Id IN (SELECT * FROM #NewInBatch)

		--------------------------------------------------------------------------------------
		-- Find and UPDATE updated records
		--------------------------------------------------------------------------------------
		Select * 
		INTO #UpdatedInBatch
		FROM (
		SELECT NEW.Id FROM #new_batch NEW
		INNER JOIN #old_batch OLD						
		ON NEW.Id = OLD.Id
		WHERE NEW.F1 <> OLD.F1
		OR NEW.F2 <> OLD.F2
		OR NEW.F3 <> OLD.F3
		) as UpdatedInBatch
		UPDATE #new_batch
		SET #new_batch.UPD = GETDATE() 
		WHERE #new_batch.Id IN (SELECT * FROM #UpdatedInBatch)


		--------------------------------------------------------------------------------------
		-- Find and UPDATE DELETED records
		--------------------------------------------------------------------------------------
		UPDATE newset
		SET newset.DEL = GETDATE()
		FROM #old_batch oldset
		INNER JOIN #new_batch newset
		ON oldset.Id = newset.Id AND newset.F3 = 'D' And oldset.F3 <> 'D'
	
		
		--------------------------------------------------------------------------------------
		-- ADD final batch to compare table
		--------------------------------------------------------------------------------------
		INSERT INTO [dbo].[Compare]
		(BatchID, Id, F1, F2, F3, UPD, INS, DEL)
		SELECT @NEW_BATCH_ID, Id, F1, F2, F3, UPD, INS, DEL FROM #new_batch

		-- DEBUG RESULT REMOVE LATER
		select * from Compare where BatchID in (@BATCH_ID, @NEW_BATCH_ID)

		--------------------------------------------------------------------------------------
		-- CLEANUP And release  memory
		--------------------------------------------------------------------------------------
		drop table #old_batch
		drop table #new_batch
		drop table #UpdatedInBatch
		drop table #NewInBatch


	END


	
		


