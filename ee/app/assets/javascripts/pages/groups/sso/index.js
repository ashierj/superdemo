import { initSamlAuthorize, redirectUserWithSSOIdentity } from 'ee/saml_sso';
import { initLanguageSwitcher } from '~/language_switcher';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

initSamlAuthorize();
redirectUserWithSSOIdentity();
initLanguageSwitcher();
renderGFM(document.body);
