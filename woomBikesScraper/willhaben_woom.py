import time

import scrapy
from scrapy.crawler import CrawlerProcess
import urllib.parse
from tqdm import tqdm

# SCRAPE ALL 52 first pages since there are 1.572 / 3 items per page < 524 currently
MAX_RESULT_PAGE = 524
ITEMS_PER_PAGE = 3


class WillhabenWoomScraper(scrapy.Spider):
    name = 'willhaben_woom'

    # Base URL for the Woom bike listings
    base_url = 'https://www.willhaben.at/iad/kaufen-und-verkaufen/marktplatz/fahrraeder/kinderfahrraeder-4558?'

    # Query params
    params = {
        'keyword': 'woom',
        'sfId': '935a397a-28ce-4674-b275-8cbc42ac496a',
        'rows': ITEMS_PER_PAGE,
        'isNavigation': 'true',
        'page': 1
    }

    # HTTP headers for the requests
    headers = {
        'user-agent': (
            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/79.0.3945.130 Safari/537.36'
        )
    }

    # Spider's custom_settings
    custom_settings = {
        'CONCURRENT_REQUESTS_PER_DOMAIN': 1,
        'DOWNLOAD_DELAY': 1,
        'AUTOTHROTTLE_ENABLED': True,
        'AUTOTHROTTLE_START_DELAY': 1,
        'AUTOTHROTTLE_MAX_DELAY': 2,
        'FEEDS': {
            'willhaben_woom_bikes.csv': {
                'format': 'csv',
                'encoding': 'utf8',
                'store_empty': True,
                'fields': [
                    'title', 'location', 'last_modified', 'price',
                    'seller_info', 'details', 'description', 'item_url'
                ]
            }
        },
        'RETRY_ENABLED': True,
        'RETRY_TIMES': 99,
        'DOWNLOADER_MIDDLEWARES': {
            'middlewares.middlewares.CustomRetryMiddleware': 543,  # Adjust priority as needed
            'scrapy.downloadermiddlewares.retry.RetryMiddleware': None,  # Disable built-in RetryMiddleware
        },
    }

    def __init__(self, *args, **kwargs):
        super(WillhabenWoomScraper, self).__init__(*args, **kwargs)
        self.page_progress_bar = tqdm(total=MAX_RESULT_PAGE, desc='Pages Scraped', position=0)
        self.item_progress_bar = tqdm(total=ITEMS_PER_PAGE * MAX_RESULT_PAGE, desc='Items Scraped', position=1)
        self.current_page = 1
        self.current_item = 0

    def start_requests(self):
        # Initialize query params
        self.params['page'] = self.current_page
        start_url = self.base_url + urllib.parse.urlencode(self.params)

        # Send the initial request
        yield scrapy.Request(url=start_url, headers=self.headers, callback=self.parse_listings, dont_filter=True)

    def parse_listings(self, response):
        # Extract and follow links to individual item pages
        item_links = response.css('a[id^="search-result-entry-header-"]::attr(href)').getall()
        print(item_links)
        print(f"The current page: {self.current_page} has following amount of items: {len(item_links)}")

        for link in item_links:
            item_url = 'https://www.willhaben.at' + link
            yield scrapy.Request(url=item_url, headers=self.headers, callback=self.parse_item)

        # Proceed to the next page if there are more pages to scrape
        isNewPageCriteriaMet = self.current_item % ITEMS_PER_PAGE == 0
        newPageTheoretical = int((self.current_item / ITEMS_PER_PAGE) + self.current_page)

        if isNewPageCriteriaMet & newPageTheoretical < MAX_RESULT_PAGE:
            print(f"isNewPageCriteriaMet: {isNewPageCriteriaMet} and newPageLead is {newPageTheoretical}")

            # sleep for 10 secs when criteria was met.
            time.sleep(10)

            self.current_page += 1
            self.page_progress_bar.update(1)
            self.params['page'] = self.current_page
            next_page_url = self.base_url + urllib.parse.urlencode(self.params)
            yield scrapy.Request(url=next_page_url,
                                 headers=self.headers,
                                 callback=self.parse_listings,
                                 dont_filter=True)
            # elif self.current_page == MAX_RESULT_PAGE:
            #    self.page_progress_bar.close()
            #    self.item_progress_bar.close()

    def parse_item(self, response):
        # Parse item details from the page
        title = response.css('h1[data-testid="ad-detail-header"]::text').get(default='').strip()
        price = response.css('span[data-testid="contact-box-price-box-price-value"]::text').get(default='').strip()
        location = response.css('div[data-testid="top-contact-box-address-box"] span:nth-child(2)::text').getall()
        location = [value.strip() for value in location]
        last_modified = response.css('span[data-testid="ad-detail-ad-edit-date-top"]::text').getall()
        last_modified = [value.strip() for value in last_modified]
        details = response.css('div[data-testid="attribute-value"]::text').getall()
        details = [detail.strip() for detail in details]
        description = response.css('div[data-testid="ad-description-Beschreibung"]::text').get(default='').strip()
        seller_info = response.css(
            'div[data-testid="ad-detail-contact-box-private-bottom"] > div:nth-of-type(4) > p::text'
        ).get(default='').strip()

        yield {
            'title': title,
            'location': location,
            'last_modified': last_modified,
            'price': price,
            'seller_info': seller_info,
            'details': details,
            'description': description,
            'item_url': response.url
        }

        # Update the item progress bar
        self.current_item += 1
        self.item_progress_bar.update(1)


if __name__ == '__main__':
    # Run the scraper
    process = CrawlerProcess(settings={
        'LOG_LEVEL': 'INFO',  # Adjust log level as needed
    })
    process.crawl(WillhabenWoomScraper)
    process.start()
