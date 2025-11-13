exports.handler = async (event) => {
  const now = new Date().toISOString();
  console.log(`[scheduler_logger] invoked at ${now} - event:`, JSON.stringify(event));
  return {
    statusCode: 200,
    body: JSON.stringify({ message: 'logged', invokedAt: now }),
  };
};

exports.second_handler = async (event) => {
  const now = new Date().toISOString();
  console.log(process.env.LAMBDA_FUNCTION_LOGGER_ARN);
  console.log(context.invokedFunctionArn);
  return {
    statusCode: 200,
    body: JSON.stringify({ message: 'second', arn: process.env.LAMBDA_FUNCTION_LOGGER_ARN }),
  };
};
