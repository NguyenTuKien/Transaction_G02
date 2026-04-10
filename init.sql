CREATE DATABASE BankDB;
GO

USE BankDB;
GO

CREATE TABLE Accounts (
    AccountID INT PRIMARY KEY,
    AccountName NVARCHAR(50),
    Balance DECIMAL(18,2) CHECK (Balance >= 0)
);
GO

-- Bơm tiền sẵn vào các tài khoản
INSERT INTO Accounts (AccountID, AccountName, Balance) VALUES 
(1, N'Tài khoản Node 1', 5000000),
(2, N'Tài khoản Node 2', 5000000),
(3, N'Tài khoản Node 3', 5000000),
(4, N'Tài khoản Node 4', 5000000),
(5, N'Tài khoản Node 5', 5000000),
(6, N'Tài khoản Node 6', 5000000);
GO