##########################################################
#
# Script to scrape Woom bike listings data
#                   from willhaben.at
#
#
##########################################################

# packages
import scrapy
from scrapy.crawler import CrawlerProcess
import urllib.parse

# SCRAPE ALL 19 first pages since there are 1661 / 90 items per page = 18,4 currently
MAX_RESULT_PAGE=19


# Willhaben scraper class
class WillhabenWoomScraper(scrapy.Spider):
    # scraper / spider name
    name = 'willhaben_woom'

    # base URL
    base_url = 'https://www.willhaben.at/iad/kaufen-und-verkaufen/marktplatz/fahrraeder/kinderfahrraeder-4558?'

    # string query parameters
    params = {
        'keyword': 'woom',
        'sfId': '935a397a-28ce-4674-b275-8cbc42ac496a',
        'rows': 90,
        'isNavigation': 'true',
        'page': 1
    }

    # custom headers
    headers = {
        'user-agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.130 '
                      'Safari/537.36'
    }

    # custom settings
    custom_settings = {
        'CONCURRENT_REQUESTS_PER_DOMAIN': 1,
        'DOWNLOAD_DELAY': 1,
        'FEEDS': {
            'woom_bikes.csv': {
                'format': 'csv',
                'encoding': 'utf8',
                'store_empty': True,
                'fields': ['title', 'location', 'last_modified', 'price', 'seller_info', 'details', 'description',
                           'item_url'],
            },
        },
    }

    # current page counter
    current_page = 1

    # crawler's entry point
    def start_requests(self):
        # init string query parameters
        self.params['page'] = self.current_page

        # generate start URL
        start_url = self.base_url + urllib.parse.urlencode(self.params)

        # crawl start URL
        yield scrapy.Request(
            url=start_url,
            headers=self.headers,
            callback=self.parse_listings
        )

    # parse listing pages
    def parse_listings(self, response):
        # loop over item links
        for link in response.css('a[aria-labelledby^="search-result-entry-header-"]::attr(href)').getall():
            item_url = 'https://www.willhaben.at' + link
            yield scrapy.Request(
                url=item_url,
                headers=self.headers,
                callback=self.parse_item
            )

        # handle pagination
        # next_page_disabled = response.css('a[aria-label="Zur nächsten Seite"].disabled')
        if self.current_page < MAX_RESULT_PAGE:
            self.current_page += 1
            self.params['page'] = self.current_page
            next_page = self.base_url + urllib.parse.urlencode(self.params)
            yield scrapy.Request(
                url=next_page,
                headers=self.headers,
                callback=self.parse_listings
            )

    # parse item page
    @staticmethod
    def parse_item(response):
        # extract item details
        title = response.css('span[data-testid="ad-detail-header"]::text').get(default='').strip()
        price = response.css('span[data-testid="contact-box-price-box-price-value-0"]::text').get(default='').strip()
        location = response.css('div[data-testid="top-contact-box-address-box"] span:nth-child(2)::text').get(
            default='').strip()
        last_modified = response.css('span[data-testid="ad-detail-ad-edit-date-top"]::text').get(default='').strip()
        details = response.css('div[data-testid="attribute-value"]::text').getall()
        details = [detail.strip() for detail in details]
        description = response.css('div[data-testid="ad-description-Beschreibung"]::text').get(default='').strip()
        seller_info = response.css('div[data-testid="contact-box-dealer-top-Infos"]::text').get(default='').strip()

        # yield item details
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


# main driver
if __name__ == '__main__':
    # run scraper
    process = CrawlerProcess()
    process.crawl(WillhabenWoomScraper)
    process.start()
