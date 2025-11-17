
export const handler = () => {
  console.log("requestSes");
  return {
    statusCode: 200,
    body: JSON.stringify({ message: 'requestSes' }),
  };
};
