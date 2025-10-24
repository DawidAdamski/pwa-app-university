class MemoryGame {
    constructor() {
        this.cards = [];
        this.flippedCards = [];
        this.matchedPairs = 0;
        this.moves = 0;
        this.score = 0;
        this.startTime = null;
        this.gameTimer = null;
        this.isPaused = false;
        this.gameBoard = document.getElementById('game-board');
        this.scoreElement = document.getElementById('score');
        this.movesElement = document.getElementById('moves');
        this.timeElement = document.getElementById('time');
        this.messageElement = document.getElementById('game-message');
        this.newGameBtn = document.getElementById('new-game');
        this.pauseGameBtn = document.getElementById('pause-game');
        
        this.symbols = ['🎯', '🎨', '🎭', '🎪', '🎫', '🎬', '🎮', '🎯', '🎨', '🎭', '🎪', '🎫', '🎬', '🎮'];
        
        this.init();
    }
    
    init() {
        this.setupEventListeners();
        this.setupPWAFeatures();
        this.newGame();
    }
    
    setupEventListeners() {
        this.newGameBtn.addEventListener('click', () => this.newGame());
        this.pauseGameBtn.addEventListener('click', () => this.togglePause());
        
        // Handle URL parameters for PWA shortcuts
        const urlParams = new URLSearchParams(window.location.search);
        if (urlParams.get('action') === 'new-game') {
            this.newGame();
        }
    }
    
    setupPWAFeatures() {
        // Install prompt
        let deferredPrompt;
        const installPrompt = document.getElementById('install-prompt');
        const installBtn = document.getElementById('install-btn');
        const dismissBtn = document.getElementById('dismiss-install');
        
        window.addEventListener('beforeinstallprompt', (e) => {
            e.preventDefault();
            deferredPrompt = e;
            installPrompt.classList.remove('hidden');
            installPrompt.classList.add('show');
        });
        
        installBtn.addEventListener('click', async () => {
            if (deferredPrompt) {
                deferredPrompt.prompt();
                const { outcome } = await deferredPrompt.userChoice;
                console.log(`User response to the install prompt: ${outcome}`);
                deferredPrompt = null;
                installPrompt.classList.add('hidden');
                installPrompt.classList.remove('show');
            }
        });
        
        dismissBtn.addEventListener('click', () => {
            installPrompt.classList.add('hidden');
            installPrompt.classList.remove('show');
        });
        
        // Handle app installation
        window.addEventListener('appinstalled', () => {
            console.log('PWA was installed');
            installPrompt.classList.add('hidden');
            installPrompt.classList.remove('show');
        });
        
        // Online/offline detection
        window.addEventListener('online', () => {
            this.showMessage('Connection restored!', 'success');
        });
        
        window.addEventListener('offline', () => {
            this.showMessage('You are offline. Game continues to work!', 'error');
        });
    }
    
    newGame() {
        this.cards = [];
        this.flippedCards = [];
        this.matchedPairs = 0;
        this.moves = 0;
        this.score = 0;
        this.isPaused = false;
        this.startTime = Date.now();
        
        if (this.gameTimer) {
            clearInterval(this.gameTimer);
        }
        
        this.updateDisplay();
        this.createCards();
        this.renderCards();
        this.startTimer();
        this.showMessage('New game started! Find all matching pairs.', 'success');
        
        // Update pause button text
        this.pauseGameBtn.textContent = 'Pause';
    }
    
    createCards() {
        // Create pairs of cards
        const cardSymbols = this.symbols.slice(0, 8); // Use 8 symbols for 16 cards
        const cardData = [...cardSymbols, ...cardSymbols]; // Duplicate for pairs
        
        // Shuffle cards
        for (let i = cardData.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [cardData[i], cardData[j]] = [cardData[j], cardData[i]];
        }
        
        this.cards = cardData.map((symbol, index) => ({
            id: index,
            symbol: symbol,
            isFlipped: false,
            isMatched: false
        }));
    }
    
    renderCards() {
        this.gameBoard.innerHTML = '';
        
        this.cards.forEach(card => {
            const cardElement = document.createElement('div');
            cardElement.className = 'game-card';
            cardElement.dataset.cardId = card.id;
            cardElement.dataset.symbol = card.symbol;
            
            if (card.isFlipped) {
                cardElement.classList.add('flipped');
            }
            if (card.isMatched) {
                cardElement.classList.add('matched');
            }
            
            cardElement.addEventListener('click', () => this.handleCardClick(card.id));
            this.gameBoard.appendChild(cardElement);
        });
    }
    
    handleCardClick(cardId) {
        if (this.isPaused) return;
        
        const card = this.cards.find(c => c.id === cardId);
        if (!card || card.isFlipped || card.isMatched) return;
        
        if (this.flippedCards.length >= 2) return;
        
        // Flip the card
        card.isFlipped = true;
        this.flippedCards.push(card);
        
        // Add visual feedback
        const cardElement = document.querySelector(`[data-card-id="${cardId}"]`);
        cardElement.classList.add('flipping');
        setTimeout(() => {
            cardElement.classList.add('flipped');
            cardElement.classList.remove('flipping');
        }, 300);
        
        if (this.flippedCards.length === 2) {
            this.moves++;
            this.updateDisplay();
            this.checkForMatch();
        }
    }
    
    checkForMatch() {
        const [card1, card2] = this.flippedCards;
        
        if (card1.symbol === card2.symbol) {
            // Match found
            card1.isMatched = true;
            card2.isMatched = true;
            this.matchedPairs++;
            this.score += 100;
            
            // Visual feedback for match
            setTimeout(() => {
                const card1Element = document.querySelector(`[data-card-id="${card1.id}"]`);
                const card2Element = document.querySelector(`[data-card-id="${card2.id}"]`);
                card1Element.classList.add('matched');
                card2Element.classList.add('matched');
            }, 500);
            
            this.showMessage('Great match!', 'success');
            
            // Check for game completion
            if (this.matchedPairs === this.cards.length / 2) {
                this.gameComplete();
            }
        } else {
            // No match
            setTimeout(() => {
                card1.isFlipped = false;
                card2.isFlipped = false;
                
                const card1Element = document.querySelector(`[data-card-id="${card1.id}"]`);
                const card2Element = document.querySelector(`[data-card-id="${card2.id}"]`);
                card1Element.classList.remove('flipped');
                card2Element.classList.remove('flipped');
            }, 1000);
            
            this.showMessage('Try again!', 'error');
        }
        
        this.flippedCards = [];
    }
    
    gameComplete() {
        const totalTime = Math.floor((Date.now() - this.startTime) / 1000);
        const minutes = Math.floor(totalTime / 60);
        const seconds = totalTime % 60;
        const timeString = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
        
        this.showMessage(`🎉 Congratulations! You completed the game in ${timeString} with ${this.moves} moves!`, 'success');
        
        // Stop timer
        if (this.gameTimer) {
            clearInterval(this.gameTimer);
        }
        
        // Save high score to localStorage
        this.saveHighScore();
        
        // Show completion animation
        setTimeout(() => {
            this.showCompletionAnimation();
        }, 1000);
    }
    
    showCompletionAnimation() {
        const cards = document.querySelectorAll('.game-card');
        cards.forEach((card, index) => {
            setTimeout(() => {
                card.style.transform = 'scale(1.1)';
                setTimeout(() => {
                    card.style.transform = 'scale(1)';
                }, 200);
            }, index * 100);
        });
    }
    
    saveHighScore() {
        const highScores = JSON.parse(localStorage.getItem('memoryHighScores') || '[]');
        const newScore = {
            score: this.score,
            moves: this.moves,
            time: Math.floor((Date.now() - this.startTime) / 1000),
            date: new Date().toISOString()
        };
        
        highScores.push(newScore);
        highScores.sort((a, b) => b.score - a.score);
        highScores.splice(10); // Keep only top 10
        
        localStorage.setItem('memoryHighScores', JSON.stringify(highScores));
    }
    
    togglePause() {
        this.isPaused = !this.isPaused;
        
        if (this.isPaused) {
            this.pauseGameBtn.textContent = 'Resume';
            this.showMessage('Game paused', 'error');
            if (this.gameTimer) {
                clearInterval(this.gameTimer);
            }
        } else {
            this.pauseGameBtn.textContent = 'Pause';
            this.showMessage('Game resumed', 'success');
            this.startTimer();
        }
    }
    
    startTimer() {
        this.gameTimer = setInterval(() => {
            if (!this.isPaused) {
                const elapsed = Math.floor((Date.now() - this.startTime) / 1000);
                const minutes = Math.floor(elapsed / 60);
                const seconds = elapsed % 60;
                this.timeElement.textContent = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
            }
        }, 1000);
    }
    
    updateDisplay() {
        this.scoreElement.textContent = this.score;
        this.movesElement.textContent = this.moves;
    }
    
    showMessage(message, type = '') {
        this.messageElement.textContent = message;
        this.messageElement.className = `game-message ${type}`;
        
        // Auto-hide message after 3 seconds
        setTimeout(() => {
            this.messageElement.textContent = '';
            this.messageElement.className = 'game-message';
        }, 3000);
    }
}

// Initialize the game when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new MemoryGame();
});

// Handle visibility change (when app is minimized/restored)
document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
        // App is hidden, could pause game or save state
        console.log('App is hidden');
    } else {
        // App is visible again
        console.log('App is visible');
    }
});

// Handle app lifecycle events
window.addEventListener('beforeunload', () => {
    // Save game state if needed
    console.log('App is about to unload');
});

// Register service worker for offline functionality
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('/sw.js')
            .then(registration => {
                console.log('ServiceWorker registration successful');
            })
            .catch(error => {
                console.log('ServiceWorker registration failed: ', error);
            });
    });
}
