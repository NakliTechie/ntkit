# Picking a chart for a process

Pick the chart from the question the reader is asking, and write the reason into the caption in one sentence ("A statechart, because the order of the refund steps is the point").

| The reader asks | Chart | Why |
|---|---|---|
| What states can this be in, and what moves it between them? | Statechart (Mermaid `stateDiagram-v2`) | States and their triggers are the content; nested states and parallel regions keep it small |
| Who passes what to whom, in what order? | Sequence diagram | Each actor gets a lane and the order reads top to bottom |
| What are the steps, and where does it split? | Flowchart | One path with its branch points |
| When does each level or threshold kick in? | Bands on one axis | The levels are positions on a scale, not steps |
| What happens over time, and how long does each part take? | Timeline | Duration and order are the content |
| How do these parts connect? | Box-and-arrow diagram | Structure, not order |

Draw it so a phone can read it: labels as the user sees them, about 20 arrows at most, and coarser states before more arrows.
