import userWorkspacesProjectsNamesQuery from '../graphql/queries/user_workspaces_projects_names.query.graphql';

export const populateWorkspacesWithProjectNames = (workspaces, projects) => {
  return workspaces.map((workspace) => {
    const project = projects.find((p) => p.id === workspace.projectId);

    return {
      ...workspace,
      projectName: project?.nameWithNamespace || workspace.projectId,
    };
  });
};
export const fetchProjectNames = async (apollo, workspaces) => {
  const projectIds = workspaces.map(({ projectId }) => projectId);

  try {
    const {
      data: { projects },
    } = await apollo.query({
      query: userWorkspacesProjectsNamesQuery,
      variables: { ids: projectIds },
    });

    return {
      projects: projects.nodes,
    };
  } catch (error) {
    return { error };
  }
};
