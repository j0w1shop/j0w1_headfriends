CREATE TABLE IF NOT EXISTS player_friends (
    id INT AUTO_INCREMENT PRIMARY KEY,
    player1 VARCHAR(50) NOT NULL,
    player2 VARCHAR(50) NOT NULL,
    UNIQUE KEY unique_friendship (player1, player2)
);