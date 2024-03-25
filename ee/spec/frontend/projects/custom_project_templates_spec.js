import MockAdapter from 'axios-mock-adapter';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import initCustomProjectTemplates from 'ee/projects/custom_project_templates';

const TAB_LINK_SELECTOR = '.js-custom-group-project-templates-nav-link';
const TAB_CONTENT_SELECTOR = '.js-custom-group-project-templates-tab-content';
const ENDPOINT = `${TEST_HOST}/users/root/available_group_templates`;
const INITIAL_CONTENT = 'initial content';
const NEXT_PAGE_CONTENT = 'page 2 content';

describe('initCustomProjectTemplates', () => {
  const generateContent = (content) => {
    return `
        <div class="js-custom-group-project-templates-nav-link">Group tab</div>
        <div class="js-custom-group-project-templates-tab-content" data-initial-templates="${ENDPOINT}">
            ${content}
            <ul class="pagination">
                <li><a href="/users/root/available_group_templates">Prev</a></li>
                <li><a href="/users/root/available_group_templates">1</a></li>
                <li><a href="/users/root/available_group_templates?page=2" class="page-2">2</a></li>
                <li><a href="#" class="page-link" rel="next">Next</a></li>
            </ul>
        </div>
    `;
  };

  const simulateTabNavigation = () => document.querySelector(TAB_LINK_SELECTOR).click();
  const simulatePagination = () => document.querySelector('.page-2').click();
  const findTabContent = () => document.querySelector(TAB_CONTENT_SELECTOR);

  beforeEach(async () => {
    const axiosMock = new MockAdapter(axios);

    axiosMock.onGet(ENDPOINT).reply(HTTP_STATUS_OK, generateContent(INITIAL_CONTENT));
    axiosMock.onGet(`${ENDPOINT}?page=2`).reply(HTTP_STATUS_OK, generateContent(NEXT_PAGE_CONTENT));

    setHTMLFixture(generateContent());
    initCustomProjectTemplates();
    simulateTabNavigation();
    await waitForPromises();
  });

  afterEach(() => resetHTMLFixture());

  it('requests the initial content', () => {
    expect(findTabContent().innerText).toContain(INITIAL_CONTENT);
  });

  it('requests content for the selected page', async () => {
    simulatePagination();
    await waitForPromises();

    expect(findTabContent().innerText).toContain(NEXT_PAGE_CONTENT);
  });
});
