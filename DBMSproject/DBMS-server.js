const express = require('express');
const mysql = require('mysql2/promise'); // Using `mysql2` for promise-based queries
const cors = require('cors');
const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// MySQL connection configuration (replace with actual database credentials)
const dbConfig = {
  host: 'localhost',
  user: 'root',
  password: 'LiI@tuP0$$!',
  database: 'library_mngmt_system_final'
};

// Route to handle form submission for `User` table insertion
app.post('/submitUserForm', async (req, res) => {
  const userData = {
    name: req.body.name,
    role: req.body.role,
    email_id: req.body.email_id,
    email_notification: req.body.email_notification ? 1 : 0, // Boolean to tinyint
    password: req.body.password,
  };

  try {
    const connection = await mysql.createConnection(dbConfig);
    const sql = `INSERT INTO User (name, role, email_id, email_notification, password) VALUES (?, ?, ?, ?, ?)`;
    const values = [userData.name, userData.role, userData.email_id, userData.email_notification, userData.password];

    await connection.execute(sql, values);
    await connection.end();

    res.status(201).send('User data added to the database');
  } catch (error) {
    console.error('Error:', error);
    res.status(500).send('Internal Server Error');
  }
});


// Route to handle updating user data
app.post('/updateUser', async (req, res) => {
  const { user_id, name, role, email_id, email_notification, password } = req.body;

  // Check if userId is provided, which is necessary to identify which user to update
  if (!user_id) {
    return res.status(400).send('User ID is required for update.');
  }

  const updatedUserData = {
    user_id,
    name,
    role,
    email_id,
    email_notification: email_notification ? 1 : 0, // Convert boolean to tinyint
    password,
  };

  try {
    const connection = await mysql.createConnection(dbConfig);
    const sql = `UPDATE User SET name = ?, role = ?, email_id = ?, email_notification = ?, password = ? WHERE user_id = ?`;
    const values = [updatedUserData.name, updatedUserData.role, updatedUserData.email_id, updatedUserData.email_notification, updatedUserData.password, updatedUserData.user_id];

    await connection.execute(sql, values);
    await connection.end();

    res.status(200).send('User data updated successfully.');
  } catch (error) {
    console.error('Error:', error);
    res.status(500).send('Internal Server Error');
  }
});

app.post('/deleteUser', async (req, res) => {
  const userId = req.body.user_id;

  if (!userId) {
    return res.status(400).json({ error: 'User ID is required for deletion.' });
  }

  try {
    const connection = await mysql.createConnection(dbConfig);

    // Delete associated records in the fine_payment table first (dependent on Transaction)
    const deleteFinePaymentsSql = 'DELETE FROM fine_payment WHERE transaction_id IN (SELECT transaction_id FROM Transaction WHERE user_id = ?)';
    await connection.execute(deleteFinePaymentsSql, [userId]);

    // Now, delete associated records in the Transaction table
    const deleteTransactionsSql = 'DELETE FROM Transaction WHERE user_id = ?';
    await connection.execute(deleteTransactionsSql, [userId]);

    // Delete associated records in the Notification table
    const deleteNotificationsSql = 'DELETE FROM Notification WHERE user_id = ?';
    await connection.execute(deleteNotificationsSql, [userId]);

    // Finally, delete the user
    const deleteUserSql = 'DELETE FROM User WHERE user_id = ?';
    await connection.execute(deleteUserSql, [userId]);

    await connection.end();
    res.status(200).json({ message: 'User and associated records deleted successfully.' });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

app.post('/checkLogin', async (req, res) => {
  const { email_id, password } = req.body;

  try {
    const connection = await mysql.createConnection(dbConfig);

    // Query to check if a user with matching email_id and password exists
    const [rows] = await connection.execute(
      `SELECT name FROM User WHERE email_id = ? AND password = ?`,
      [email_id, password]
    );

    await connection.end();

    if (rows.length > 0) {
      // If user exists, send the user_name as part of the response
      const userName = rows[0].name;
      res.status(200).json({ user_name: userName });
    } else {
      res.status(401).send('Invalid username or password');
    }
  } catch (error) {
    console.error('Error:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Route to handle form submission for `Staff` table insertion
app.post('/submitStaffForm', async (req, res) => {
  // Extract staff data from the request body
  const staffData = {
    name: req.body.name,
    role: req.body.role,
    email_id: req.body.email_id,
    password: req.body.password,
    library_id: 1,
    salary: 12000.00,
  };

  try {
    const connection = await mysql.createConnection(dbConfig);

    // SQL query to insert data without the staff_id (since it's auto_increment)
    const sql = `INSERT INTO Staff (name, library_id, role, email_id, password, salary) VALUES (?, ?, ?, ?, ?, ?)`;
    const values = [staffData.name, staffData.library_id, staffData.role, staffData.email_id, staffData.password, staffData.salary];

    // Execute the SQL query with the specified values
    await connection.execute(sql, values);
    await connection.end();

    res.status(201).send('Staff data added to the database');
  } catch (error) {
    console.error('Error:', error);
    res.status(500).send('Internal Server Error');
  }
});

app.post('/checkStaffLogin', async (req, res) => {
  const { email_id, password } = req.body;

  try {
    const connection = await mysql.createConnection(dbConfig);

    // Query to check if a staff member with matching email_id and password exists
    const [rows] = await connection.execute(
      `SELECT name FROM Staff WHERE email_id = ? AND password = ?`,
      [email_id, password]
    );

    await connection.end();

    if (rows.length > 0) {
      // If staff member exists, send the name as part of the response
      const staffName = rows[0].name;
      res.status(200).json({ staff_name: staffName });
    } else {
      res.status(401).send('Invalid username or password');
    }
  } catch (error) {
    console.error('Error:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Route to handle book search by either title, author, or ISBN
app.get('/searchBook', async (req, res) => {
  const { title, author, ISBN } = req.query;

  try {
    const connection = await mysql.createConnection(dbConfig);
    let sql = '';
    const values = [];

    // Check which parameter is provided and set SQL query accordingly
    if (title) {
      sql = `SELECT title, author, ISBN, publisher, availability FROM Book WHERE title LIKE ?`;
      values.push(`%${title}%`);
    } else if (author) {
      sql = `SELECT title, author, ISBN, publisher, availability FROM Book WHERE author LIKE ?`;
      values.push(`%${author}%`);
    } else if (ISBN) {
      sql = `SELECT title, author, ISBN, publisher, availability FROM Book WHERE ISBN = ?`;
      values.push(ISBN);
    } else {
      return res.status(400).send('Please provide a title, author, or ISBN to search');
    }

    const [rows] = await connection.execute(sql, values);
    await connection.end();

    if (rows.length > 0) {
      res.status(200).json(rows); // Return the list of books found with availability
    } else {
      res.status(404).send('No books found matching the criteria');
    }
  } catch (error) {
    console.error('Error:', error);
    res.status(500).send('Internal Server Error');
  }
});


app.post('/submitTransactionForm', async (req, res) => {
  try {
    const { user_name, book_title } = req.body;
    console.log('Received request:', req.body);

    const connection = await mysql.createConnection(dbConfig);

    // Retrieve user_id based on user_name
    const [[user]] = await connection.execute(
      `SELECT user_id FROM User WHERE name = ?`,
      [user_name]
    );
    if (!user) {
      await connection.end();
      return res.status(404).json({ error: 'User not found' });
    }
    const user_id = user.user_id;

    // Retrieve book_id based on book_title
    const [[book]] = await connection.execute(
      `SELECT book_id FROM Book WHERE title = ?`,
      [book_title]
    );
    if (!book) {
      await connection.end();
      return res.status(404).json({ error: 'Book not found' });
    }
    const book_id = book.book_id;

    // Prepare transaction data
    const transactionData = {
      book_id,
      user_id,
      item_type: 'Book',
      date_borrowed: new Date().toISOString().split('T')[0],
      return_date: new Date(new Date().setDate(new Date().getDate() + 4)).toISOString().split('T')[0],
      damage_fine: 0.00,
      late_fees: 0.00
    };

    // Insert transaction data
    const sql = `
      INSERT INTO Transaction (book_id, user_id, item_type, date_borrowed, return_date, damage_fine, late_fees)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `;
    const values = [
      transactionData.book_id,
      transactionData.user_id,
      transactionData.item_type,
      transactionData.date_borrowed,
      transactionData.return_date,
      transactionData.damage_fine,
      transactionData.late_fees
    ];

    const [result] = await connection.execute(sql, values);

    // Update book availability
    await connection.execute(
      `UPDATE Book SET availability = 0 WHERE book_id = ?`,
      [book_id]
    );

    // Retrieve and return transaction details
    const [[transactionDetails]] = await connection.execute(`
      SELECT u.name AS user_name, b.title AS book_title, t.book_id, t.item_type, t.date_borrowed, t.return_date
      FROM Transaction t
      JOIN User u ON u.user_id = t.user_id
      JOIN Book b ON b.book_id = t.book_id
      WHERE t.transaction_id = ?
    `, [result.insertId]);

    await connection.end();

    res.status(201).json(transactionDetails);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Route to add a new book to the Book table
app.post('/addBook', async (req, res) => {
  const {
    book_id,
    availability,
    title,
    author,
    ISBN,
    edition,
    publisher,
    publication_year,
    is_digital,
    shelf_number
  } = req.body;

  try {
    const connection = await mysql.createConnection(dbConfig);
    const sql = `INSERT INTO Book (book_id, availability, title, author, ISBN, edition, publisher, publication_year, is_digital, shelf_number)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;
    const values = [book_id, availability, title, author, ISBN, edition, publisher, publication_year, is_digital, shelf_number];

    await connection.execute(sql, values);
    await connection.end();

    res.status(201).send('Book added successfully.');
  } catch (error) {
    console.error('Error:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Route to update an existing book in the Book table
app.post('/updateBook', async (req, res) => {
  const {
    book_id,
    availability,
    title,
    author,
    ISBN,
    edition,
    publisher,
    publication_year,
    is_digital,
    shelf_number
  } = req.body;

  if (!book_id) {
    return res.status(400).send('Book ID is required for update.');
  }

  try {
    const connection = await mysql.createConnection(dbConfig);
    const sql = `UPDATE Book
                 SET availability = ?, title = ?, author = ?, ISBN = ?, edition = ?, publisher = ?, publication_year = ?, is_digital = ?, shelf_number = ?
                 WHERE book_id = ?`;
    const values = [availability, title, author, ISBN, edition, publisher, publication_year, is_digital, shelf_number, book_id];

    await connection.execute(sql, values);
    await connection.end();

    res.status(200).send('Book updated successfully.');
  } catch (error) {
    console.error('Error:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Route to delete a book from the Book table
app.post('/deleteBook', async (req, res) => {
  const { book_id } = req.body;

  if (!book_id) {
    return res.status(400).send('Book ID is required for deletion.');
  }

  try {
    const connection = await mysql.createConnection(dbConfig);
    const sql = `DELETE FROM Book WHERE book_id = ?`;

    await connection.execute(sql, [book_id]);
    await connection.end();

    res.status(200).send('Book deleted successfully.');
  } catch (error) {
    console.error('Error:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Route to generate book report
app.get('/genReportBook', async (req, res) => {
  let connection;

  try {
    // Establish connection to database
    connection = await mysql.createConnection(dbConfig);

    // SQL query for generating the report
    const query = `
      SELECT
        -- Total number of books
        (SELECT COUNT(*) FROM Book) AS total_books,
      
        -- Number of available books
        (SELECT COUNT(*) FROM Book WHERE availability = 1) AS available_books,
      
        -- Number of digital books
        (SELECT COUNT(*) FROM Book WHERE is_digital = 1) AS digital_books,
      
        -- Average publication year of all books
        (SELECT AVG(publication_year) FROM Book WHERE publication_year IS NOT NULL) AS avg_publication_year,
      
        -- Publisher with the most books
        (SELECT publisher
         FROM Book
         GROUP BY publisher
         ORDER BY COUNT(*) DESC
         LIMIT 1) AS most_frequent_publisher,
      
        -- Author with the most books
        (SELECT author
         FROM Book
         GROUP BY author
         ORDER BY COUNT(*) DESC
         LIMIT 1) AS author_with_most_books,
      
        -- Oldest book title and year
        (SELECT title FROM Book WHERE publication_year = 
         (SELECT MIN(publication_year) FROM Book WHERE publication_year IS NOT NULL)
         LIMIT 1) AS oldest_book_title,
         
        (SELECT MIN(publication_year) FROM Book WHERE publication_year IS NOT NULL) AS oldest_book_year,
      
        -- Newest book title and year
        (SELECT title FROM Book WHERE publication_year = 
         (SELECT MAX(publication_year) FROM Book WHERE publication_year IS NOT NULL)
         LIMIT 1) AS newest_book_title,
         
        (SELECT MAX(publication_year) FROM Book WHERE publication_year IS NOT NULL) AS newest_book_year;
    `;

    // Execute the query
    const [rows] = await connection.execute(query);

    // Send the result as JSON response
    res.json(rows[0]);
  } catch (error) {
    console.error("Error generating report:", error);
    res.status(500).json({ error: "Failed to generate book report" });
  } finally {
    // Close the database connection if it was opened
    if (connection) {
      await connection.end();
    }
  }
});

app.get('/api/getTriggerLogs', async (req, res) => {
  let connection;

  try {
    connection = await mysql.createConnection(dbConfig);
    const query = 'SELECT action_type, book_id, title, publisher FROM my_book_log ORDER BY action_type DESC LIMIT 20';
    const [results] = await connection.execute(query);
    
    res.json(results);
  } catch (err) {
    console.error('Error fetching logs:', err);
    res.status(500).json({ error: 'Failed to fetch trigger logs' });
  } finally {
    if (connection) await connection.end();
  }
});


app.post('/return-book', async (req, res) => {
  const { transactionId, returnDate } = req.body;
  let connection;

  try {
    connection = await mysql.createConnection(dbConfig);
    
    const [results] = await connection.execute('CALL ReturnBook(?, ?)', [transactionId, returnDate]);

    if (results[0] && results[0].length > 0) {
      const { message, lateFee } = results[0][0];
      res.json({ message, lateFee: lateFee || 0, lateFeeApplicable: lateFee > 0 });
    } else {
      res.json({ message: 'Book returned successfully!', lateFeeApplicable: false });
    }
  } catch (err) {
    console.error('Error executing query:', err);
    res.status(500).json({ error: 'Failed to return book. Please try again later.' });
  } finally {
    if (connection) await connection.end();
  }
});

// Route to generate user report
app.get('/genReportUser', async (req, res) => {
  let connection;

  try {
    // Establish connection to database
    connection = await mysql.createConnection(dbConfig);

    // SQL query for generating the report
    const query = `
      SELECT
        -- Total number of users
        (SELECT COUNT(*) FROM User) AS total_users,
      
        -- Total number of students and staff
        (SELECT COUNT(*) FROM User WHERE role = 'Student') AS total_students,
        (SELECT COUNT(*) FROM User WHERE role = 'Staff') AS total_staff,
      
        -- Count of users with email notifications enabled
        (SELECT COUNT(*) FROM User WHERE email_notification = 1) AS users_with_notifications,
      
        -- Most common role
        (SELECT role
         FROM User
         GROUP BY role
         ORDER BY COUNT(*) DESC
         LIMIT 1) AS most_common_role,
      
        -- Percentage of each role
        (SELECT ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM User), 2)
         FROM User
         WHERE role = 'Student') AS student_percentage,
      
        (SELECT ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM User), 2)
         FROM User
         WHERE role = 'Staff') AS staff_percentage,
      
        -- Users without email IDs
        (SELECT COUNT(*) FROM User WHERE email_id IS NULL) AS users_without_email;
    `;

    // Execute the query
    const [rows] = await connection.execute(query);

    // Send the result as JSON response
    res.json(rows[0]);
  } catch (error) {
    console.error("Error generating user report:", error);
    res.status(500).json({ error: "Failed to generate user report" });
  } finally {
    // Close the database connection if it was opened
    if (connection) {
      await connection.end();
    }
  }
});

// Start the server
app.listen(port, () => {
  console.log(`Server is running at http://localhost:${port}`);
});
