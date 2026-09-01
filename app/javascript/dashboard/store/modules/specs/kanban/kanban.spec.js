import { actions } from '../../kanban';
import types from '../../../mutation-types';
import { KanbanTasks } from '../../../../api/kanban';

vi.mock('../../../../api/kanban', () => ({
  KanbanPipelines: {},
  KanbanStages: {},
  KanbanMembers: {},
  KanbanAutomations: {},
  KanbanTasks: { show: vi.fn() },
}));

const CURRENT_USER_ID = 7;
const cardOnBoard = { id: 1, pipeline_id: 10, stage_id: 100, position: 0 };

const buildContext = (records = [cardOnBoard]) => ({
  commit: vi.fn(),
  state: { activePipelineId: 10, records },
  rootGetters: { getCurrentUserID: CURRENT_USER_ID },
});

describe('#syncTaskFromCable', () => {
  beforeEach(() => vi.clearAllMocks());

  it('ignores a card that belongs to another pipeline', async () => {
    const context = buildContext();

    await actions.syncTaskFromCable(context, {
      task: { ...cardOnBoard, pipeline_id: 99, stage_id: 200 },
    });

    expect(KanbanTasks.show).not.toHaveBeenCalled();
    expect(context.commit).not.toHaveBeenCalled();
  });

  // The bug this guards: an AI agent moving a card through the API authenticates
  // with a human's access token, so the broadcast names that human as the
  // performer. Their own board used to discard the event and only caught up on a
  // page refresh.
  it('applies a move performed under the current user token from elsewhere', async () => {
    const context = buildContext();
    const moved = { ...cardOnBoard, stage_id: 200, position: 3 };
    KanbanTasks.show.mockResolvedValue({ data: moved });

    await actions.syncTaskFromCable(context, {
      task: { id: 1, pipeline_id: 10, stage_id: 200, position: 3 },
      performer: { id: CURRENT_USER_ID },
    });

    expect(KanbanTasks.show).toHaveBeenCalledWith(1);
    expect(context.commit).toHaveBeenCalledWith(types.EDIT_KANBAN_TASK, moved);
  });

  it('skips the refetch when the local card already matches the broadcast', async () => {
    const context = buildContext();

    await actions.syncTaskFromCable(context, {
      task: { id: 1, pipeline_id: 10, stage_id: 100, position: 0 },
      performer: { id: CURRENT_USER_ID },
    });

    expect(KanbanTasks.show).not.toHaveBeenCalled();
    expect(context.commit).not.toHaveBeenCalled();
  });

  it('applies a move performed by another agent', async () => {
    const context = buildContext();
    const moved = { ...cardOnBoard, stage_id: 200 };
    KanbanTasks.show.mockResolvedValue({ data: moved });

    await actions.syncTaskFromCable(context, {
      task: { id: 1, pipeline_id: 10, stage_id: 200, position: 0 },
      performer: { id: 42 },
    });

    expect(context.commit).toHaveBeenCalledWith(types.EDIT_KANBAN_TASK, moved);
  });

  it('adds a card the board has never seen', async () => {
    const context = buildContext([]);
    const created = { id: 2, pipeline_id: 10, stage_id: 100, position: 0 };
    KanbanTasks.show.mockResolvedValue({ data: created });

    await actions.syncTaskFromCable(context, {
      task: created,
      performer: { id: CURRENT_USER_ID },
    });

    expect(context.commit).toHaveBeenCalledWith(types.ADD_KANBAN_TASK, created);
  });
});
