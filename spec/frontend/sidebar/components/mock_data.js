export const getIssueCrmContactsQueryResponse = {
  data: {
    issue: {
      __typename: 'Issue',
      id: 'gid://gitlab/Issue/123',
      customerRelationsContacts: {
        nodes: [
          {
            id: 'gid://gitlab/CustomerRelations::Contact/1',
            firstName: 'Someone',
            lastName: 'Important',
            email: 'si@gitlab.com',
            phone: null,
            description: null,
            organization: null,
          },
          {
            id: 'gid://gitlab/CustomerRelations::Contact/5',
            firstName: 'Marty',
            lastName: 'McFly',
            email: null,
            phone: null,
            description: null,
            organization: null,
          },
        ],
      },
    },
  },
};

export const issueCrmContactsUpdateNullResponse = {
  data: {
    issueCrmContactsUpdated: null,
  },
};

export const issueCrmContactsUpdateResponse = {
  data: {
    issueCrmContactsUpdated: {
      __typename: 'Issue',
      id: 'gid://gitlab/Issue/123',
      customerRelationsContacts: {
        nodes: [
          {
            id: 'gid://gitlab/CustomerRelations::Contact/13',
            firstName: 'Dave',
            lastName: 'Davies',
            email: 'dd@gitlab.com',
            phone: '+44 20 1111 2222',
            description: 'Vice President',
            organization: null,
          },
        ],
      },
    },
  },
};

export const mockSuggestedColors = {
  '#009966': 'Green-cyan',
  '#8fbc8f': 'Dark sea green',
  '#3cb371': 'Medium sea green',
  '#00b140': 'Green screen',
  '#013220': 'Dark green',
  '#6699cc': 'Blue-gray',
  '#0000ff': 'Blue',
  '#e6e6fa': 'Lavender',
  '#9400d3': 'Dark violet',
  '#330066': 'Deep violet',
  '#808080': 'Gray',
  '#36454f': 'Charcoal grey',
  '#f7e7ce': 'Champagne',
  '#c21e56': 'Rose red',
  '#cc338b': 'Magenta-pink',
  '#dc143c': 'Crimson',
  '#ff0000': 'Red',
  '#cd5b45': 'Dark coral',
  '#eee600': 'Titanium yellow',
  '#ed9121': 'Carrot orange',
  '#c39953': 'Aztec Gold',
};
