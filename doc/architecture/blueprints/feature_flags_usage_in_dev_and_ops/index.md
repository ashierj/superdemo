---
status: proposed
creation-date: "2023-10-09"
authors: [ "@rymai" ]
coach: "@DylanGriffith"
approvers: []
owning-stage: "~devops::non_devops"
participating-stages: []
---

# Feature Flags usage in GitLab development and operations

This blueprint builds upon [the Development Feature Flags Architecture blueprint](../feature_flags_development/index.md).

## Summary

Feature flags are critical both in developing and operating GitLab, but in the current state
of the process, they can lead to production issues, and introduce a lot of manual and maintenance work.

The goals of this blueprint is to make the process safer, more maintainable, transparent and lightweight.

## Motivations

### Feature flag use-cases

Feature flags can be used for different purposes:

- Fast rollback (most feature flags): De-risking GitLab.com deployments by having a
  very fast way to disable changes in the event of a production incident.
- De-risking on-premise release of new features: In some cases, a new feature might
  result in a performance regression for on-premise customers
  ([example](https://gitlab.com/gitlab-org/gitlab/-/issues/336070#note_1523983444)).
  Providing a flag in this case allows customers to disable the new feature until
  it's performant enough.
- Work in progress: Development teams want to hide partially complete features.
  This also includes features that aren't yet ready to be rolled out to all
  customers (scaling or UX concerns) but we still want to test them internally or
  for specific opt-in customers. For instance,
  [the `ci_enable_live_trace` feature flag isn't compatible with Object storage](https://gitlab.com/gitlab-org/gitlab/-/issues/24177#note_1311242146)
  so the flag needs to stay until Object storage is compatible with it.
- Future setting: It's tempting to use a feature flag instead of a proper instance
  setting (no database migration, no backend/frontend/UI change), but it's almost
  always a bad idea and
  [these kind of feature flags should be ported to an instance/group/project/user setting at some point](https://gitlab.com/gitlab-org/gitlab/-/issues/395931).
- Operations: Site reliability engineer or Support engineer can use these flags to
  disable potentially resource-heavy features in order to the instance back to a
  more stable and available state.

We need to better categorize our feature flags.

### Production incidents related to feature flags

Feature flags have caused production incidents on GitLab.com ([1](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/5289), [2](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/4155), [3](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/16366)).

We need to prevent this for the sake of GitLab.com stability and long-term maintainability
& quality of the GitLab codebase.

### Technical debt caused by feature flags

Feature flags are also becoming an ever-growing source of technical debt: there are currently
[591 feature flags in the GitLab codebase](../../../user/feature_flags.md).

We need to reduce feature flags count for the sake of long-term maintainability & quality of the GitLab codebase.

## Goal

The goal of this blueprint is to improve the feature flag process by making it:

- safer
- more maintainable
- more lightweight & automated
- more transparent

## Challenges

### Complex feature flag rollout process

The feature flag rollout process is currently:

- Complex: Rollout issues that are very manual and includes a lot of checkboxes
  (including non-relevant checkboxes).
  Engineers often don't use these issues, which tend to become stale and forgotten over time.
- Not very transparent: Feature flag changes are logged in several places far from the rollout
  issue, which makes it hard to understand the latest feature flag state.
- Far from production processes: Rollout issues are created in the `gitlab-org/gitlab` project
  (far from the production issue tracker).
- There is no consistent path to rolling out feature flags: we leave to the judgement of the
  engineer to trade-off between speed and safety. There should be a standardized set of rollout
  steps.

### Technical debt and codebase complexity

[The challenges from the Development Feature Flags Architecture blueprint still stands](../feature_flags_development/index.md#challenges).

Additionally, there are new challenges:

- If a feature flag is enabled by default, and is disabled in an on-premise installation,
  then when the feature flag is removed, the feature suddenly becomes enabled on the
  on-premise instance and cannot be rolled backed to the previous behavior.

### Multiple source of truth for feature flag default states and observability

We currently show the feature flag default states in several places, for different intended audiences:

**GitLab customers**

- [User documentation](../../../user/feature_flags.md):
  List all feature flags and their metadata so that GitLab customers can tweak feature flags on
  their instance. Also useful for GitLab.com users that want to check the default state of a feature flag.

**Site reliability and Delivery engineers**

- [Internal GitLab.com feature flag state change issues](https://gitlab.com/gitlab-com/gl-infra/feature-flag-log/-/issues):
  For each change of a feature flag state on GitLab.com, an issue is created in this project.
- [Internal GitLab.com feature flag state change logs](https://nonprod-log.gitlab.net):
  Filter logs with `source: feature` and `env: gprd` to see feature flag state change logs.

**GitLab Engineering & Infra/Quality Directors / VPs, and CTO**

- [Internal Sisense dashboard](https://app.periscopedata.com/app/gitlab/792066/Engineering-::-Feature-Flags):
  Feature flag metrics over time, grouped per DevOps groups.

**GitLab Engineering and Product managers**

- ["Feature flags requiring attention" monthly reports](https://gitlab.com/gitlab-org/quality/triage-reports/-/issues/?sort=created_date&state=opened&search=Feature%20flags&in=TITLE&assignee_id=None&first_page_size=100):
  Same data as the above Internal Sisense dashboard but for a specific DevOps
  group, presented in an issue and assigned to the group's Engineering managers.

**Anyone who wants to check feature flag default states**

- [Unofficial feature flags dashboard](https://samdbeckham.gitlab.io/feature-flags/):
  A user-friendly dashboard which provides useful filtering.

This leads to confusion for almost all feature flag stakeholders (Development engineers, Engineering managers, Site reliability, Delivery engineers).

## Proposal

### Improve feature flags implementation and usage

- [Reduce the likelihood of mis-configuration and human-error at the implementation step](https://gitlab.com/groups/gitlab-org/-/epics/11553)
  - Remove the "percentage of time" strategy in favor of "percentage of actors"
- [Improve the feature flag development documentation](https://gitlab.com/groups/gitlab-org/-/epics/5324)

### Introduce new feature flag `type`s

It's clear that the `development` feature flag type actually includes several use-cases:

- Fast rollback (YAML value: `fast_rollback`): Derisking GitLab.com deployments by having a very fast way to disable changes in the
  event of a production incident.
- De-risking on-premise release of new features (YAML value: `on_premise_derisk`) ([example](https://gitlab.com/gitlab-org/gitlab/-/issues/336070#note_1523983444)):
  In some cases, a new feature might result in a performance regression for on-premise customers
- Work in progress (YAML value: `work_in_progress`): Development teams want to hide partially complete features.
  This also includes features that aren't yet ready to be rolled out to all customers (scaling or UX concerns)
  but we still want to test them internally or for specific opt-in customers
- Future setting (YAML value: `future_setting`): It's tempting to use a feature flag instead of a proper
  instance/group/project setting (no database migration, no backend/frontend/UI change), but it's almost
  always a bad idea and
  [these kind of feature flags should be ported to an instance setting at some point](https://gitlab.com/gitlab-org/gitlab/-/issues/395931).
  Note that `ops` feature flags can be used if the setting isn't meant to be changed through the UI.

### Introduce constraints per feature flag type

Each feature flag type will be assigned specific constraints regarding:

- Allowed values for the `default_enabled` attribute
- Maximum Life Span (MLS): the duration starting on the introduction of the feature flag (i.e. when it's merged into `master`).
  We don't introduce a life span that would start on the global GitLab.com enablement (or `default_enabled: true` when
  applicable) so that there's incentive to rollout and delete feature flags as quickly as possible.

The MLS will be enforced through automation, reporting & regular review meetings at the section level.

Following are the constraints for each feature flag type:

- `fast_rollback`
  - `default_enabled` **must not** be set to `true`. This kind of feature flag is meant to lower the risk on GitLab.com, thus
    there's no need to keep the flag in the codebase after it's been enabled on GitLab.com.
  - MLS: 2 months
- `on_premise_derisk`
  - `default_enabled` can be set to `true`
  - MLS: 3 months
- `work_in_progress`
  - `default_enabled` **must not** be set to `true`.
  - MLS: 6 months
- `future_setting`
  - `default_enabled` can be set to `true`. In that case, the setting to replace the feature flag should default to be enabled.
  - MLS: 6 months (remember that this type should only be used to save time before introducing a proper instance setting)
- `ops`
  - `default_enabled` can be set to `true`
  - MLS: Unlimited (remember that using this type should follow a conscious decision not to introduce an instance setting)

### Introduce a new `feature_issue_url` and `cleanup_issue_url` fields

Keeping the URL to the original feature issue will allow automated cross-linking from the rollout
and logging issues. The new field for this information is `feature_issue_url`.

In many cases, the rollout issues aren't sufficient to track the "next step" after a feature flag
rollout has been done, for several reasons:

- The team prefers to keep the feature flag enabled by default for a few releases before actually
  removing the flag ([example](https://gitlab.com/gitlab-org/gitlab/-/issues/416297#note_1448217853)).
- A feature flag "cleanup" is more complex than just removing the flag. Discussions need to happen
  to decide whether to introduce a new instance setting, or if the feature can actually be enabled by default
  without a feature flag. In those cases, a rollout issue doesn't make sense and it's better to open a new
  dedicated "cleanup" issue and document it in the feature flag YAML definition file with the `cleanup_issue_url`
  field.

That way, the rollout issue would only concern the actual production changes (i.e. enablement/disablement
of the flag on production) and should be closed as soon as the production change is confirmed to work as expected.

For instance:

```yaml
---
name: auto_devops_banner_disabled
feature_issue_url: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/12345
introduced_by_url: https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/14218
rollout_issue_url: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/83652
cleanup_issue_url: https://gitlab.com/gitlab-org/gitlab/-/issues/395931
milestone: '10.0'
type: fast_rollback
group: group::pipeline execution
default_enabled: false
```

### Streamline the feature flag rollout process

1. Transition to **create rollout issues in the
   [Production issue tracker](https://gitlab.com/gitlab-com/gl-infra/production/-/issues)** and adapt the
   template to be closer to the
   [Change management issue template](https://gitlab.com/gitlab-com/gl-infra/production/-/blob/master/.gitlab/issue_templates/change_management.md)
   (see [this issue](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/2780) for inspiration)
1. Ensure the rollout DRI stays online for a few hours after enabling a feature flag (ideally they'd enable the flag at the
   beginning of their day) in case of any issue with the feature flag
1. Provide a standardized set of rollout steps. Trade-offs to consider include:
    - Likelihood of errors occurring
    - Total actors (users / requests / projects / groups) affected by the feature flag rollout,
      e.g. it will be bad if 100,000 users cannot log in when we roll out for 1%
    - How long to wait between each step. Some FF only need to wait 10 minutes per step, some
      flags should wait 24 hours. Ideally there should be automation to actively verify there
      is no adverse effect for each step.
1. Automate most rollout steps, such as:
     - [Let the author know that their feature has been deployed to staging / canary / production environments](https://gitlab.com/gitlab-org/quality/triage-ops/-/issues/1403)
     - [Cross-link actual feature flag state change (from Chatops project) to rollout issues](https://gitlab.com/gitlab-org/gitlab/-/issues/290770)
     - Ping DRI and their group on Slack upon feature flag state change
     - Let the author know that their `default_enabled: true` MR has been deployed to production and that
       the feature flag can be removed from production
     - Enforce MLS of feature flags through automation, reporting & regular review at the section level

### Provide better SSOT for the feature flag default states and current states & state changes on GitLab.com

**GitLab customers**

- [User documentation](../../../user/feature_flags.md):
  Keep the current page but add filtering and sorting, similarly to the
  [unofficial feature flags dashboard](https://samdbeckham.gitlab.io/feature-flags/).

**Site reliability and Delivery engineers**

- [Internal GitLab.com feature flag state change issues](https://gitlab.com/gitlab-com/gl-infra/feature-flag-log/-/issues):
  Ensure this issue tracker is useful and used by the relevant stakeholders.
- [Internal GitLab.com feature flag state change logs](https://nonprod-log.gitlab.net):
  Ensure this issue tracker is useful and used by the relevant stakeholders.

**GitLab Engineering & Infra/Quality Directors / VPs, and CTO**

- [Internal Sisense dashboard](https://app.periscopedata.com/app/gitlab/792066/Engineering-::-Feature-Flags):
  Streamline the current dashboard to be more useful for its stakeholders.

**GitLab Engineering and Product managers**

- ["Feature flags requiring attention" monthly reports](https://gitlab.com/gitlab-org/quality/triage-reports/-/issues/?sort=created_date&state=opened&search=Feature%20flags&in=TITLE&assignee_id=None&first_page_size=100):
  Make the current reports more actionable by improving documentation and best-practices around feature flags.

## Iterations

This work is being done as part of dedicated epic:
[Improve internal usage of Feature Flags](https://gitlab.com/groups/gitlab-org/-/epics/3551).
This epic describes a meta reasons for making these changes.

## Resources

- [Short-lived or Long-lived Flags? Explaining Feature Flag lifespans](https://configcat.com/blog/2022/07/08/how-long-should-you-keep-feature-flags/)
