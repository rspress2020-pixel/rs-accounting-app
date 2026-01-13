const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';

// ============================================================================
// Middleware Configuration
// ============================================================================

// CORS configuration
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'http://localhost:3001',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Body parser middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// Logging middleware
if (NODE_ENV === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// ============================================================================
// Health Check Endpoint
// ============================================================================

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: NODE_ENV
  });
});

// ============================================================================
// API Routes
// ============================================================================

// TODO: Import and register route modules
// app.use('/api/accounts', require('./routes/accounts'));
// app.use('/api/transactions', require('./routes/transactions'));
// app.use('/api/users', require('./routes/users'));

// ============================================================================
// Error Handling Middleware
// ============================================================================

app.use((err, req, res, next) => {
  console.error('Error:', err);

  const status = err.status || err.statusCode || 500;
  const message = err.message || 'Internal Server Error';

  res.status(status).json({
    error: {
      status,
      message,
      ...(NODE_ENV === 'development' && { stack: err.stack })
    }
  });
});

// 404 Not Found Handler
app.use((req, res) => {
  res.status(404).json({
    error: {
      status: 404,
      message: `Route ${req.originalUrl} not found`
    }
  });
});

// ============================================================================
// Server Instance
// ============================================================================

let server;

async function startServer() {
  try {
    // TODO: Initialize database connections here
    // await initializeDatabase();

    server = app.listen(PORT, () => {
      console.log(`
╔════════════════════════════════════════════════════════════╗
║         RS Accounting App - Backend Server Started          ║
╠════════════════════════════════════════════════════════════╣
║ Port:        ${PORT.toString().padEnd(46)}║
║ Environment: ${NODE_ENV.padEnd(46)}║
║ Timestamp:   ${new Date().toISOString().padEnd(46)}║
╚════════════════════════════════════════════════════════════╝
      `);
    });

    return server;
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// ============================================================================
// Graceful Shutdown Handler
// ============================================================================

async function gracefulShutdown(signal) {
  console.log(`\n${signal} received. Starting graceful shutdown...`);

  if (server) {
    server.close(async () => {
      console.log('HTTP server closed');

      try {
        // TODO: Close database connections here
        // await closeDatabase();

        console.log('Database connections closed');
        console.log('Graceful shutdown completed');
        process.exit(0);
      } catch (error) {
        console.error('Error during graceful shutdown:', error);
        process.exit(1);
      }
    });

    // Force shutdown after timeout (30 seconds)
    const shutdownTimeout = setTimeout(() => {
      console.error('Graceful shutdown timeout exceeded. Force exiting...');
      process.exit(1);
    }, 30000);

    shutdownTimeout.unref();
  } else {
    process.exit(0);
  }
}

// Handle termination signals
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  gracefulShutdown('uncaughtException');
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  gracefulShutdown('unhandledRejection');
});

// ============================================================================
// Start Server
// ============================================================================

if (require.main === module) {
  startServer();
}

module.exports = app;
