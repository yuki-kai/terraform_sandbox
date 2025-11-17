import type { APIGatewayProxyResult, APIGatewayEvent } from 'aws-lambda';
import { SchedulerClient, CreateScheduleCommand, FlexibleTimeWindowMode } from '@aws-sdk/client-scheduler';

// Scheduler クライアント
const schedulerClient = new SchedulerClient({ region: 'ap-northeast-1' });

/**
 * リクエストボディの scheduledTime に指定した日時に一度だけ Lambda を実行するスケジュールを作成します。
 * body 例: { "id": "abc", "scheduledTime": "2025-11-11T15:30:00Z", "payload": { ... } }
 */
export const handler = async (event: APIGatewayEvent): Promise<APIGatewayProxyResult> => {
  try {
    const body = event.body ? JSON.parse(event.body) : {};

    // 実行時刻（ISO 形式）: 指定がなければデフォルトで5分後
    let when: Date;
    if (body.scheduledTime) {
      when = new Date(body.scheduledTime);
      if (isNaN(when.getTime())) throw new Error('scheduledTime が不正です');
    } else {
      when = new Date();
      when.setMinutes(when.getMinutes() + 5);
    }

    // at() 形式で一回だけ実行: at(YYYY-MM-DDThh:mm:ss)
    const isoNoMs = when.toISOString().replace(/\.\d{3}Z$/, '');
    const scheduleExpression = `at(${isoNoMs})`;

    const scheduleName = `schedule-${body.id ?? Date.now()}`;

    if (!process.env.TARGET_LAMBDA_ARN) throw new Error('TARGET_LAMBDA_ARN が未設定です');
    if (!process.env.SCHEDULER_ROLE_ARN) throw new Error('SCHEDULER_ROLE_ARN が未設定です');

    const input = {
      type: 'scheduled_event',
      payload: body.payload ?? body,
    };

    const cmd = new CreateScheduleCommand({
      Name: scheduleName,
      ScheduleExpression: scheduleExpression,
      FlexibleTimeWindow: { Mode: FlexibleTimeWindowMode.OFF },
      Target: {
        // 実行対象のLambdaのARN
        Arn: process.env.TARGET_LAMBDA_ARN,
        // SchedulerがAssumeしてターゲットを実行するためのロールのARN
        RoleArn: process.env.SCHEDULER_ROLE_ARN,
        Input: JSON.stringify(input),
      },
      Description: `one-shot schedule for ${scheduleName}`,
      State: 'ENABLED',
    });

    const resp = await schedulerClient.send(cmd);

    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'schedule created', scheduleName, scheduleArn: resp.ScheduleArn, scheduledAt: isoNoMs }),
    };
  } catch (err: any) {
    console.error('create schedule error:', err);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: err?.message ?? String(err) }),
    };
  }
};
