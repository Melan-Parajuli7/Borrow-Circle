module.exports = (err, req, res, next) => {
  let status = err.statusCode || 500;
  let message = err.isOperational ? err.message : 'Something went wrong';

  if (err.code === 'LIMIT_FILE_SIZE') { status = 400; message = 'File too large (max 5MB)'; }
  if (err.code === 'LIMIT_FILE_TYPE' || err.code === 'LIMIT_UNEXPECTED_FILE') {
    status = 400; message = err.message;
  }

  if (status === 500) console.error(err); // log unexpected errors in the terminal
  res.status(status).json({ success: false, message });
};