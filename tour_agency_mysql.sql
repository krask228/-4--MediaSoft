DROP DATABASE IF EXISTS tour_agency;
CREATE DATABASE tour_agency CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE tour_agency;

DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS tours;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    phone VARCHAR(20),
    registered_at DATE NOT NULL DEFAULT (CURRENT_DATE)
);

CREATE TABLE tours (
    tour_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(120) NOT NULL,
    country VARCHAR(80) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    CONSTRAINT chk_tour_price CHECK (price > 0),
    CONSTRAINT chk_tour_dates CHECK (end_date >= start_date)
);

CREATE TABLE bookings (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    tour_id INT NOT NULL,
    booking_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    persons_count INT NOT NULL,
    status VARCHAR(20) NOT NULL,
    CONSTRAINT chk_persons_count CHECK (persons_count > 0),
    CONSTRAINT chk_booking_status CHECK (status IN ('new', 'confirmed', 'cancelled')),
    CONSTRAINT fk_bookings_customer FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id) ON DELETE CASCADE,
    CONSTRAINT fk_bookings_tour FOREIGN KEY (tour_id)
        REFERENCES tours(tour_id) ON DELETE RESTRICT
);

CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    payment_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    amount DECIMAL(10,2) NOT NULL,
    method VARCHAR(20) NOT NULL,
    payment_status VARCHAR(20) NOT NULL,
    CONSTRAINT chk_payment_amount CHECK (amount > 0),
    CONSTRAINT chk_payment_method CHECK (method IN ('card', 'cash', 'transfer')),
    CONSTRAINT chk_payment_status CHECK (payment_status IN ('paid', 'pending', 'refunded')),
    CONSTRAINT fk_payments_booking FOREIGN KEY (booking_id)
        REFERENCES bookings(booking_id) ON DELETE CASCADE
);

INSERT INTO customers (full_name, email, phone, registered_at) VALUES
('Иван Петров', 'ivan.petrov@mail.com', '+79991112233', '2026-01-10'),
('Мария Соколова', 'm.sokolova@mail.com', '+79992223344', '2026-02-05'),
('Алексей Кузнецов', 'alex.kuz@mail.com', '+79993334455', '2026-02-20'),
('Ольга Миронова', 'olga.mironova@mail.com', '+79994445566', '2026-03-02'),
('Дмитрий Власов', 'd.vlasov@mail.com', '+79995556677', '2026-03-15');

INSERT INTO tours (title, country, price, start_date, end_date) VALUES
('Выходные в Стамбуле', 'Турция', 45000.00, '2026-05-12', '2026-05-16'),
('Рим и Флоренция', 'Италия', 78000.00, '2026-06-01', '2026-06-08'),
('Париж классический', 'Франция', 82000.00, '2026-06-15', '2026-06-22'),
('Грузия гастрономическая', 'Грузия', 39000.00, '2026-05-25', '2026-05-30');

INSERT INTO bookings (customer_id, tour_id, booking_date, persons_count, status) VALUES
(1, 1, '2026-04-10', 2, 'confirmed'),
(2, 2, '2026-04-12', 1, 'confirmed'),
(3, 3, '2026-04-13', 3, 'new'),
(4, 1, '2026-04-14', 1, 'cancelled'),
(5, 4, '2026-04-15', 2, 'confirmed'),
(2, 4, '2026-04-16', 1, 'new');

INSERT INTO payments (booking_id, payment_date, amount, method, payment_status) VALUES
(1, '2026-04-10', 90000.00, 'card', 'paid'),
(2, '2026-04-12', 78000.00, 'transfer', 'paid'),
(3, '2026-04-14', 50000.00, 'card', 'pending'),
(4, '2026-04-14', 10000.00, 'cash', 'refunded'),
(5, '2026-04-15', 78000.00, 'card', 'paid'),
(6, '2026-04-16', 10000.00, 'cash', 'pending');

SELECT SUM(amount) AS total_paid_amount
FROM payments
WHERE payment_status = 'paid';

SELECT
    c.full_name,
    t.title AS tour_title,
    b.persons_count,
    b.status AS booking_status
FROM bookings b
JOIN customers c ON c.customer_id = b.customer_id
JOIN tours t ON t.tour_id = b.tour_id
ORDER BY c.full_name;

SELECT
    t.title AS tour_title,
    COUNT(b.booking_id) AS bookings_count
FROM tours t
LEFT JOIN bookings b ON b.tour_id = t.tour_id
GROUP BY t.title
ORDER BY bookings_count DESC, t.title;

SELECT
    c.full_name,
    SUM(p.amount) AS customer_total_paid
FROM customers c
JOIN bookings b ON b.customer_id = c.customer_id
JOIN payments p ON p.booking_id = b.booking_id
GROUP BY c.full_name
HAVING SUM(p.amount) > (
    SELECT AVG(amount) FROM payments
)
ORDER BY customer_total_paid DESC;

SELECT
    b.booking_id,
    c.full_name,
    t.title AS tour_title,
    IFNULL(SUM(p.amount), 0) AS paid_sum,
    t.price * b.persons_count AS total_cost,
    CASE
        WHEN IFNULL(SUM(p.amount), 0) = 0 THEN 'Не оплачено'
        WHEN IFNULL(SUM(p.amount), 0) < t.price * b.persons_count THEN 'Частично оплачено'
        ELSE 'Оплачено полностью'
    END AS payment_level
FROM bookings b
JOIN customers c ON c.customer_id = b.customer_id
JOIN tours t ON t.tour_id = b.tour_id
LEFT JOIN payments p ON p.booking_id = b.booking_id AND p.payment_status <> 'refunded'
GROUP BY b.booking_id, c.full_name, t.title, t.price, b.persons_count
ORDER BY b.booking_id;
