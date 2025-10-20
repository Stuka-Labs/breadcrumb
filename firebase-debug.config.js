// Firebase Debug Configuration
// This file enables comprehensive debugging for all Firebase operations

module.exports = {
  // Enable verbose logging
  debug: true,
  
  // Log all Firestore operations
  firestore: {
    debug: true,
    logLevel: 'debug',
    logQueries: true,
    logWrites: true,
    logReads: true,
    logDeletes: true,
    logTransactions: true,
    logBatchOperations: true
  },
  
  // Log all Auth operations
  auth: {
    debug: true,
    logSignIns: true,
    logSignOuts: true,
    logPasswordChanges: true,
    logEmailChanges: true,
    logUserCreation: true,
    logUserDeletion: true
  },
  
  // Log all Storage operations
  storage: {
    debug: true,
    logUploads: true,
    logDownloads: true,
    logDeletes: true,
    logMetadata: true
  },
  
  // Log all Functions operations
  functions: {
    debug: true,
    logCalls: true,
    logResults: true,
    logErrors: true
  },
  
  // Performance monitoring
  performance: {
    debug: true,
    logTraces: true,
    logNetworkRequests: true,
    logDatabaseOperations: true
  },
  
  // Analytics debugging
  analytics: {
    debug: true,
    logEvents: true,
    logUserProperties: true,
    logCustomParameters: true
  }
};
