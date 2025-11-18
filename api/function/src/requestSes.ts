import {
  SESClient,
  SendEmailCommand,
  SendEmailCommandInput,
} from "@aws-sdk/client-ses";

const ses = new SESClient({ region: 'ap-northeast-1' });

export const handler = async () => {
  const params: SendEmailCommandInput = {
    Source: "issi0430bjc@gmail.com",
    Destination: { ToAddresses: ["issi0430bjc@gmail.com"] },
    Message: {
      Subject: { Data: "test subject" },
      Body: {
        Text: { Data: "test body" },
      },
    },
  };
  
  const command = new SendEmailCommand(params);
  
  try {
    await ses.send(command);
  } catch (error) {
    console.error(error);
  }
};
