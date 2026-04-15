USE master;
GO

-- 1. Xóa Link cũ nếu có
IF EXISTS (SELECT srvname FROM sysservers WHERE srvname = 'NODE_2_LINK')
    EXEC sp_dropserver 'NODE_2_LINK', 'droplogins';
GO

-- 2. Tạo Linked Server trỏ thẳng IP Máy 2
EXEC sp_addlinkedserver
     @server     = N'NODE_2_LINK',
     @srvproduct = N'SqlServer',
     @provider   = N'MSOLEDBSQL',
     @datasrc    = N'172.20.10.2,1433'; -- Đổi IP tương ứng với máy đích
GO

-- 3. Cấu hình xác thực (Dùng SA của máy 2)
EXEC sp_addlinkedsrvlogin
     @rmtsrvname = N'NODE_2_LINK',
     @useself    = N'False',
     @locallogin = NULL,
     @rmtuser    = N'sa',
     @rmtpassword= N'YourStrong!Passw0rd'; 
GO

-- 4. BẬT RPC và TRANSACTION (Bắt buộc)
EXEC sp_serveroption 'NODE_2_LINK', 'rpc', 'true';
EXEC sp_serveroption 'NODE_2_LINK', 'rpc out', 'true';
EXEC sp_serveroption 'NODE_2_LINK', 'remote proc transaction promotion', 'true';
GO

-- 5. Test xem Máy 1 đã nhìn thấy Máy 2 chưa
EXEC sp_testlinkedserver N'NODE_2_LINK';
GO