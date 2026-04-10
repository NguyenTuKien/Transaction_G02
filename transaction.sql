SET XACT_ABORT ON;
GO

USE BankDB;
GO

BEGIN TRY
BEGIN DISTRIBUTED TRANSACTION;

    DECLARE @TransferAmount DECIMAL(18,2) = 1000000;

    -- 1. TRỪ TIỀN tại máy Cục bộ (Máy 1)
UPDATE dbo.Accounts
SET Balance = Balance - @TransferAmount
WHERE AccountID = 1;

-- 2. CỘNG TIỀN tại máy Từ xa (Máy 2) thông qua Linked Server
UPDATE NODE_2_LINK.BankDB.dbo.Accounts
SET Balance = Balance + @TransferAmount
WHERE AccountID = 2;

-- 3. Xác nhận giao dịch
COMMIT TRANSACTION;

PRINT N'GIAO TÁC PHÂN TÁN THÀNH CÔNG! Đã chuyển 1 triệu từ Node 1 sang Node 2.';
END TRY
BEGIN CATCH
IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    PRINT N'XẢY RA LỖI - ĐÃ ROLLBACK GIAO TÁC TRÊN CẢ 2 MÁY.';
    PRINT ERROR_MESSAGE();
END CATCH;
GO