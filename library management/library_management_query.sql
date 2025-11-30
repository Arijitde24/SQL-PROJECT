SELECT * FROM library_management.tbl_book;
SELECT * FROM library_management.tbl_book_authors;
SELECT * FROM library_management.tbl_book_copies;
SELECT * FROM library_management.tbl_book_loans;
SELECT * FROM library_management.tbl_borrower;
SELECT * FROM library_management.tbl_library_branch;
SELECT * FROM library_management.tbl_publisher;

---1. how many copies of the book titled "The Lost Tribe" are owned by the library_branch whose name is "Sharpstone"?
GO
CREATE PROCEDURE GetCopies
	@bookname nvarchar(100),
	@branchname nvarchar(100)
AS
BEGIN
    SELECT b.book_Title,lb.library_branch_BranchName,bc.book_copies_No_Of_Copies FROM library_management.tbl_book as b
	INNER JOIN library_management.tbl_book_copies AS bc
	ON bc.book_copies_BookID=b.book_BookID
	INNER JOIN library_management.tbl_library_branch as lb
	ON bc.book_copies_BranchID = lb.library_branch_BranchID
	WHERE b.book_Title = @bookname AND lb.library_branch_BranchName = @branchname;
END;
GO

EXEC GetCopies
	@bookname='The Lost Tribe',
	@branchname='Sharpstown'

---ANS: 5 

---2 how many copies of 'The Lost Tribe' in every branch


GO
CREATE PROCEDURE GetCopiesAllBranch
	@bookname nvarchar(100)
AS
BEGIN
    SELECT b.book_Title,lb.library_branch_BranchName,bc.book_copies_No_Of_Copies FROM library_management.tbl_book as b
	INNER JOIN library_management.tbl_book_copies AS bc
	ON bc.book_copies_BookID=b.book_BookID
	INNER JOIN library_management.tbl_library_branch as lb
	ON bc.book_copies_BranchID = lb.library_branch_BranchID
	WHERE b.book_Title = @bookname;
END;
GO

EXEC GetCopiesAllBranch 'The Lost Tribe'

/*ANS:

  book_Title   library_branch_BranchName	book_copies_No_Of_Copies
The Lost Tribe	      Sharpstown	                     5
The Lost Tribe	       Central	                         5
The Lost Tribe	       Saline	                         5
The Lost Tribe	      Ann Arbor	                         5
*/

---3. name of all borrowers who has not checked out any books

GO
CREATE PROC NoLoans
AS
SELECT borrower_BorrowerName FROM library_management.tbl_borrower  
WHERE NOT EXISTS
(SELECT * FROM library_management.tbl_book_loans
WHERE book_loans_CardNo=borrower_CardNo)
GO

/*ALTERNATE
GO
CREATE PROC NoLoans
AS
SELECT borrower_BorrowerName FROM library_management.tbl_borrower 
WHERE borrower_CardNo NOT IN
(SELECT book_loans_CardNo from library_management.tbl_book loans 
)
GO*/

EXEC NoLoans

---ANS: Jane Smith

/* #4- For each book that is loaned out from the "Sharpstown" branch and a particular DueDate, retrieve the book title, the borrower's name, and the borrower's address.  */

GO
CREATE PROC Loaners_info
@DueDate date = NULL,
@Branchname varchar(50) = 'Sharpstown'
AS
SELECT b.book_Title,lb.library_branch_BranchName,bor.borrower_BorrowerName,bor.borrower_BorrowerAddress FROM library_management.tbl_book as b
INNER JOIN library_management.tbl_book_loans as bl
ON bl.book_loans_BookID = b.book_BookID
INNER JOIN library_management.tbl_borrower as bor
ON bl.book_loans_CardNo=bor.borrower_CardNo
INNER JOIN library_management.tbl_library_branch as lb
ON bl.book_loans_BranchID = lb.library_branch_BranchID
WHERE bl.book_loans_DueDate=@DueDate AND lb.library_branch_BranchName = @Branchname
GO

EXEC Loaners_info '2/3/18'

/* #5- For each library branch, retrieve the branch name and the total number of books loaned out from that branch.  */

GO
CREATE PROC book_loaned_each_branch
AS
SELECT lb.library_branch_BranchName,COUNT(book_loans_BranchID) AS books_loaned FROM library_management.tbl_book_loans AS bl
INNER JOIN library_management.tbl_library_branch as lb
ON lb.library_branch_BranchID = bl.book_loans_BranchID
GROUP BY lb.library_branch_BranchName;
GO

EXEC book_loaned_each_branch

/*ANS: 
library_branch_BranchName	books_loaned
       Ann Arbor	             20
       Central	                 11
       Saline	                 10
     Sharpstown	                 10
*/

---#6- Retrieve the names, addresses, and number of books checked out for all borrowers who have more than five books checked out.

GO
CREATE PROC BooksLoanedOut
(@BooksCheckedOut INT = 5)
AS
SELECT bor.borrower_BorrowerName,bor.borrower_BorrowerAddress,COUNT(book_loans_CardNo) AS books_loaned FROM library_management.tbl_book_loans AS bl
INNER JOIN library_management.tbl_borrower AS bor
ON bl.book_loans_CardNo = bor.borrower_CardNo
GROUP BY bor.borrower_BorrowerName,borrower_BorrowerAddress
HAVING COUNT(book_loans_CardNo)>=@BooksCheckedOut
ORDER BY books_loaned DESC;
GO

EXEC BooksLoanedOut

---7. For each book authored by "Stephen King", retrieve the title and the number of copies owned by the library branch whose name is "Central".

GO
CREATE PROC BookbyAuthorandBranch
@authorname VARCHAR(50)='Stephen King',
@branchname VARCHAR(50)='Central'
AS
SELECT b.book_title,a.book_authors_AuthorName,lb.library_branch_BranchName,c.book_copies_No_Of_Copies FROM library_management.tbl_book as b
INNER JOIN library_management.tbl_book_authors a
ON a.book_authors_BookID = b.book_BookID
INNER JOIN library_management.tbl_book_copies c
ON c.book_copies_BookID = b.book_BookID
INNER JOIN library_management.tbl_library_branch lb
ON lb.library_branch_BranchID=c.book_copies_BranchID
WHERE a.book_authors_AuthorName = @authorname AND lb.library_branch_BranchName=@branchname
GO

EXEC BookbyAuthorandBranch