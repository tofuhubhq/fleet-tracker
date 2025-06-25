import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHello(): string {
    return 'Hello World!';
  }

  // Contains the logic for the webhook event
  processChirpstackWebhookEvent(event): Promise<any> {
    console.info(event);
    return new Promise((resolve) => {
      return resolve({});
    });
  }
}
