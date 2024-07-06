import scrapy
from scrapy.crawler import CrawlerProcess
import urllib.parse

# SCRAPE ALL 18 first pages since there are 1600 / 90 items per page < 18 currently
MAX_RESULT_PAGE = 18


class WillhabenWoomScraper(scrapy.Spider):
    name = 'willhaben_woom'

    # Base URL for the Woom bike listings
    base_url = 'https://www.willhaben.at/iad/kaufen-und-verkaufen/marktplatz/fahrraeder/kinderfahrraeder-4558?'

    # Query params
    params = {
        'keyword': 'woom',
        'sfId': '935a397a-28ce-4674-b275-8cbc42ac496a',
        'rows': 90,
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
            'woom_bikes_new.csv': {
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

    # Current page counter
    current_page = 1

    def start_requests(self):
        # Initialize query params
        self.params['page'] = self.current_page
        start_url = self.base_url + urllib.parse.urlencode(self.params)

        # Send the initial request
        yield scrapy.Request(url=start_url, headers=self.headers, callback=self.parse_listings)

    def parse_listings(self, response):
        # Extract and follow links to individual item pages
        item_links = response.css('a[aria-labelledby^="search-result-entry-header-"]::attr(href)').getall()
        for link in item_links:
            item_url = 'https://www.willhaben.at' + link
            yield scrapy.Request(url=item_url, headers=self.headers, callback=self.parse_item)

        # Check if there are more pages to scrape
        if self.current_page < MAX_RESULT_PAGE:
            self.current_page += 1
            self.params['page'] = self.current_page
            next_page_url = self.base_url + urllib.parse.urlencode(self.params)
            yield scrapy.Request(url=next_page_url, headers=self.headers, callback=self.parse_listings)

    @staticmethod
    def parse_item(response):
        # parse item details from the page
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


if __name__ == '__main__':
    # Run the scraper
    process = CrawlerProcess(settings={
        'LOG_LEVEL': 'INFO',  # Adjust log level as needed
    })
    process.crawl(WillhabenWoomScraper)
    process.start()
