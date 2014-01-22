DECLARE @Id INT
DECLARE @BATCH_ID INT
DECLARE @NEW_BATCH_ID INT

DECLARE @F1 VARCHAR(100)
DECLARE @F2 VARCHAR(100)
DECLARE @F3 VARCHAR(100)
DECLARE @UPD DATE
DECLARE @INS DATE
DECLARE @DEL DATE



	SET @BATCH_ID = (SELECT MAX(BatchID) FROM Compare)
	IF @BATCH_ID IS NULL
		BEGIN 
			-- First batch, create initial load
			SET @BATCH_ID = 0
			INSERT INTO [dbo].[Compare]
			(BatchID, Id, F1, F2, F3, UPD, INS, DEL)
			SELECT @BATCH_ID, Id, F1, F2, F3, CONVERT(DATE, '1900-01-01'), GETDATE(), CONVERT(DATE, '1900-01-01') FROM [dbo].[Master]
		END
	ELSE
		BEGIN 
			-- Add new row to batch
			SET @NEW_BATCH_ID = @BATCH_ID + 1

			-- Old batch to compare against
			SELECT Id, F1, F2, F3, UPD, INS, DEL into #old_batch from [dbo].[Compare] WHERE [BatchID] = @BATCH_ID
			SELECT Id, F1, F2, F3, CONVERT(DATE, '1900-01-01') as UPD, CONVERT(DATE, '1900-01-01') as INS, CONVERT(DATE, '1900-01-01') as DEL into #new_batch from [dbo].[Master] 
	

			-- Sync Old Timestaps with stamps in New set
			UPDATE #new_batch
			SET UPD, INS, DEL

			WHERE #new_batch.Id IN (




			-- Detect new records in NEW_BATCH
			Select * 
			INTO #NewInBatch
			FROM (
			SELECT ID FROM #new_batch 
			EXCEPT
			SELECT ID FROM #old_batch
			) as NewInNewBatch
			-- UPDATE INSERT FLAG
			UPDATE #new_batch
			SET #new_batch.INS = GETDATE() 
			WHERE #new_batch.Id IN (SELECT * FROM #NewInBatch)


			-- Find updated records
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
			-- Update UPDATE flag
			UPDATE #new_batch
			SET #new_batch.UPD = GETDATE() 
			WHERE #new_batch.Id IN (SELECT * FROM #UpdatedInBatch)

			-- Debug print result
			select * from #new_batch



			-- Add final batch to compare table
			INSERT INTO [dbo].[Compare]
			(BatchID, Id, F1, F2, F3, UPD, INS, DEL)
			SELECT @NEW_BATCH_ID, Id, F1, F2, F3, UPD, INS, DEL FROM #new_batch
			


			select * from Compare where BatchID in (@BATCH_ID, @NEW_BATCH_ID)

			drop table #old_batch
			drop table #new_batch
			drop table #UpdatedInBatch
			drop table #NewInBatch

		END


	
		


