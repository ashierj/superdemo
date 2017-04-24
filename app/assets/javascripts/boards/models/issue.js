/* eslint-disable no-unused-vars, space-before-function-paren, arrow-body-style, arrow-parens, comma-dangle, max-len */
/* global ListLabel */
/* global ListMilestone */
/* global ListUser */

import Vue from 'vue';

class ListIssue {
  constructor (obj) {
    this.globalId = obj.id;
    this.id = obj.iid;
    this.title = obj.title;
    this.confidential = obj.confidential;
    this.dueDate = obj.due_date;
    this.subscribed = obj.subscribed;
    this.labels = [];
    this.selected = false;
    this.position = obj.relative_position || Infinity;
    this.milestone_id = obj.milestone_id;

    if (obj.milestone) {
      this.milestone = new ListMilestone(obj.milestone);
    }

    obj.labels.forEach((label) => {
      this.labels.push(new ListLabel(label));
    });

    this.assignees = obj.assignees.map(a => new ListUser(a));
  }

  addLabel (label) {
    if (!this.findLabel(label)) {
      this.labels.push(new ListLabel(label));
    }
  }

  findLabel (findLabel) {
    return this.labels.filter(label => label.title === findLabel.title)[0];
  }

  removeLabel (removeLabel) {
    if (removeLabel) {
      this.labels = this.labels.filter(label => removeLabel.title !== label.title);
    }
  }

  removeLabels (labels) {
    labels.forEach(this.removeLabel.bind(this));
  }

  getLists () {
    return gl.issueBoards.BoardsStore.state.lists.filter(list => list.findIssue(this.id));
  }

  update (url) {
    const data = {
      issue: {
        milestone_id: this.milestone ? this.milestone.id : null,
        due_date: this.dueDate,
        assignee_id: this.assignee ? this.assignee.id : null,
        label_ids: this.labels.map((label) => label.id)
      }
    };

    if (!data.issue.label_ids.length) {
      data.issue.label_ids = [''];
    }

    return Vue.http.patch(url, data);
  }
}

window.ListIssue = ListIssue;
