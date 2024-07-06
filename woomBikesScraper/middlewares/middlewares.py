# middlewares.py

import random
import time
from scrapy.exceptions import IgnoreRequest
from scrapy.downloadermiddlewares.retry import RetryMiddleware


class CustomRetryMiddleware(RetryMiddleware):
    def __init__(self, settings):
        super().__init__(settings)
        self.too_many_requests_min_delay = 600  # 10 minutes in seconds
        self.too_many_requests_max_delay = 900  # 15 minutes in seconds
        self.waiting = False
        self.max_retry_times = settings.getint('RETRY_TIMES', 99)  # default 99 times

    def process_response(self, request, response, spider):
        if response.status == 429:  # Too Many Requests
            delay = random.randint(self.too_many_requests_min_delay, self.too_many_requests_max_delay)
            spider.logger.warning(f'Received 429 status code. Waiting for {delay} seconds...')
            self.waiting = True
            time.sleep(delay)
            self.waiting = False
            return self._retry(request, 'Too Many Requests', spider) or response
        return super().process_response(request, response, spider)

    def process_request(self, request, spider):
        if self.waiting:
            spider.logger.info('Waiting due to previous 429 response. Skipping request.')
            raise IgnoreRequest("Waiting due to previous 429 response")
        return None
