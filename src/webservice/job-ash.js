/* Historical presentation of existing Desktop ASH metrics and native cursors. */
(() => {
  'use strict';
  const SVG_NS = 'http://www.w3.org/2000/svg';
  // Exact Desktop vectorsetup palette, reordered for the legend (not reclassified).
  const PG_COLORS = [
    ['BCPU', '#00CC00'], ['CPU', '#00FF00'], ['IO', '#004AE7'],
    ['System_IO', '#4080F0'], ['Timeout', '#E46800'], ['IPC', '#FFD700'],
    ['Client', '#5C440B'], ['Extension', '#882044'], ['Activity', '#717354'],
    ['BufferPin', '#C02800'], ['Lock', '#9F9371'], ['LWLock', '#F06EAA']
  ];
  const MYSQL_COLORS = [
    ['BCPU', '#00CC00'], ['CPU', '#00FF00'], ['Idle', '#4080F0'],
    ['Lock', '#E46800'], ['Network', '#FFD700'], ['Table_IO', '#5C440B'],
    ['File_IO', '#882044'], ['SXLock', '#717354'], ['Cond', '#C02800'],
    ['RWLock', '#9F9371'], ['Mutex', '#F06EAA'], ['Other', '#808080']
  ];
  const num = value => value !== '' && value != null && Number.isFinite(Number(value)) ? Number(value) : 0;
  const valid = value => value !== '' && value != null && Number.isFinite(Number(value));
  const attr = (tag, attrs = {}, text) => {
    const node = document.createElement(tag);
    for (const [key, value] of Object.entries(attrs)) node.setAttribute(key, String(value));
    if (text !== undefined) node.textContent = String(text);
    return node;
  };
  const svgNode = (tag, attrs = {}, text) => {
    const node = document.createElementNS(SVG_NS, tag);
    for (const [key, value] of Object.entries(attrs)) node.setAttribute(key, String(value));
    if (text !== undefined) node.textContent = String(text);
    return node;
  };
  const field = (row, ...names) => {
    if (!row || typeof row !== 'object') return undefined;
    // Prefer requested field names, not JSON property insertion order. MySQL
    // wait-event rows contain both native wait_event_type and classified group;
    // the latter must win so Mutex/Cond/RWLock bars match the chart palette.
    for (const name of names) {
      const wanted = name.toLowerCase().replace(/_/g, '');
      const match = Object.keys(row).find(key => key.toLowerCase().replace(/_/g, '') === wanted);
      if (match !== undefined) return row[match];
    }
    return undefined;
  };
  const label = value => value == null || value === '' ? 'Unavailable' : String(value);
  const timestamp = epoch => new Date(Number(epoch) * 1000).toLocaleTimeString([], {hour: '2-digit', minute: '2-digit', second: '2-digit'});
  const stampLong = epoch => new Date(Number(epoch) * 1000).toLocaleString();
  const round = value => num(value).toFixed(2);
  function mount(root) {
    const source = new URL(root.dataset.source, location.href);
    if (source.origin !== location.origin) throw new Error('ASH must load from the same Jobs service.');
    const chart = root.querySelector('.hdb-ash-chart');
    const legend = root.querySelector('.hdb-ash-legend');
    const status = root.querySelector('.hdb-ash-status');
    const bounds = root.querySelector('.hdb-ash-window');
    const inspector = root.querySelector('.hdb-ash-inspector-body');
    const inspectorTitle = root.querySelector('.hdb-ash-inspector-title');
    const limitations = root.querySelector('.hdb-ash-limitations');
    const workspace = root.querySelector('.hdb-ash-workspace');
    const range = root.querySelector('.hdb-ash-range');
    const rangeBegin = root.querySelector('[data-ash-range-begin]');
    const rangeEnd = root.querySelector('[data-ash-range-end]');
    const rangeError = root.querySelector('.hdb-ash-range-error');
    const panes = {
      sql: root.querySelector('[data-rows="sql"]'),
      events: root.querySelector('[data-rows="events"]'),
      sessions: root.querySelector('[data-rows="sessions"]')
    };
    let selection = {}, current = null, controller = null, timer = null, generation = 0;
    let view = 'sql-text', focus = 'sql', count = {sql: 50, events: 50, sessions: 50};
    let selectedID = null;
    const colorsFor = () => current && current.database === 'pg' ? PG_COLORS : MYSQL_COLORS;
    const key = name => String(name || 'Other').toLowerCase().replace(/_/g, '');
    const colorFor = name => (colorsFor().find(entry => key(entry[0]) === key(name)) || [null, '#8693A9'])[1];
    const category = row => label(field(row, 'category', 'group', 'wait_event_type'));
    const localISO = epoch => {
      const d = new Date(Number(epoch) * 1000);
      return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 23);
    };
    const syncRange = report => {
      if (!valid(report.captured_begin) || !valid(report.captured_end)) return;
      const min = localISO(report.captured_begin), max = localISO(report.captured_end);
      for (const input of [rangeBegin, rangeEnd]) {
        input.min = min; input.max = max;
      }
      if (document.activeElement !== rangeBegin) rangeBegin.value = localISO(report.begin);
      if (document.activeElement !== rangeEnd) rangeEnd.value = localISO(report.end);
    };
    function clearedWindow() {
      const next = {};
      for (const k of ['begin','end','pointer_begin','pointer_end'])
        if (Object.prototype.hasOwnProperty.call(selection, k)) next[k] = selection[k];
      return next;
    }
    function clearToRange() {
      // Empty selection means the entire current benchmark Job. Preserve
      // neither a stale SQL detail nor pointer coordinates.
      selection = {};
      focus = 'sql'; selectedID = null; view = 'sql-text';
      rangeError.textContent = '';
      load();
    }
    function selectRow(kind, row, tab) {
      let id;
      if (kind === 'sql') id = field(row, 'queryid', 'digest', 'query_id');
      else if (kind === 'events') id = field(row, 'wait_event');
      else id = field(row, 'pid', 'processlist_id', 'session_id');
      // A NULL query ID is valid in the Desktop ASH SQL text cursor.
      // Avoid silently ignoring click events on such rows.
      if (kind === 'sql' && (id === null || id === undefined)) id = '';
      if (id === undefined || id === null) {
        status.textContent = 'Cannot open this '+kind+' row: no session/event identifier was captured.';
        inspector.replaceChildren(attr('p',{'class':'hdb-ash-empty'},status.textContent));
        return;
      }
      selection = clearedWindow();
      selection[kind === 'sql' ? 'sql_id' : kind === 'events' ? 'event_id' : 'session_id'] = id;
      focus = kind === 'events' ? 'event' : kind === 'sessions' ? 'session' : 'sql';
      selectedID = String(id);
      view = focus === 'sql' ? (tab || 'sql-text') : focus;
      const what = focus === 'event' ? 'wait event' : focus === 'session' ? 'session' : 'SQL statement';
      inspectorTitle.textContent = 'Details · '+(id === '' ? 'NULL SQL ID' : String(id));
      inspector.replaceChildren(attr('p',{'class':'hdb-ash-help'},'Loading '+what+' details…'));
      load();
    }
    function legendPaint(rows) {
      legend.replaceChildren();
      const native = [...new Set(rows.map(category))];
      const used = new Set(native.map(key));
      const standard = colorsFor().map(([name]) => name).filter(name => used.has(key(name)));
      const extras = native.filter(name => !standard.some(known => key(known) === key(name))).sort();
      for (const name of [...standard, ...extras]) {
        const swatch = attr('span', {'class':'hdb-ash-legend-item'});
        swatch.append(attr('i', {'class':'hdb-ash-swatch','style':'background-color:'+colorFor(name)}),
          attr('span', {}, name));
        legend.append(swatch);
      }
    }
    function paintChart(report) {
      chart.replaceChildren();
      const points = (report.chart || []).filter(r => valid(r.begin) && valid(r.end) && valid(r.aas) && Number(r.end) > Number(r.begin));
      if (!points.length) {
        chart.append(attr('p', {'class': 'hdb-ash-empty'}, 'No chart samples were captured for this Job.'));
        legend.replaceChildren();
        return;
      }
      legendPaint(points);
      const left = Math.min(...points.map(r => Number(r.begin)));
      const right = Math.max(...points.map(r => Number(r.end)));
      if (!(right > left)) return;
      const WIDTH = 1160, HEIGHT = 290, m = {left: 56, right: 22, top: 38, bottom: 36};
      const pw = WIDTH - m.left - m.right, ph = HEIGHT - m.top - m.bottom;
      const byBucket = new Map();
      // Native SQL has already normalised AAS for each sample cadence:
      // PostgreSQL collects every 1 second; MySQL/MariaDB/VillageSQL every
      // 5 seconds (avoiding observer overhead). Never multiply AAS again.
      // All three MySQL-family engines must resolve overlapping archives
      // identically before stacking, or their plots become incomparable.
      const nativeSampleSeconds={pg:1,mysql:5,maria:5,vsql:5}[report.database];
      const mysqlFamily=nativeSampleSeconds===5;
      const snapshots = mysqlFamily ? new Map() : null;
      const canonical = name => (colorsFor().find(([known]) => key(known)===key(name)) || [name])[0];
      for (const row of points) {
        const start = num(row.begin), end = num(row.end);
        const k = String(start) + ':' + String(end);
        let bucket;
        if (mysqlFamily) {
          if (!snapshots.has(k)) snapshots.set(k,new Map());
          const polls=snapshots.get(k);
          const poll=valid(row._poll_epoch) ? String(row._poll_epoch) : 'legacy';
          if (!polls.has(poll)) polls.set(poll,{
            start,end,groups:new Map(),sampleIds:new Set(),rows:0,
            pollTime:valid(row._poll_epoch)?num(row._poll_epoch):end
          });
          bucket=polls.get(poll);
          if (valid(row.sample_id)) bucket.sampleIds.add(String(row.sample_id));
          bucket.rows++;
        } else {
          if (!byBucket.has(k)) byBucket.set(k, {start,end,groups:new Map()});
          bucket=byBucket.get(k);
        }
        const cls=canonical(category(row));
        bucket.groups.set(cls,(bucket.groups.get(cls)||0)+Math.max(0,num(row.aas)));
      }
      if (mysqlFamily) {
        for (const [key,polls] of snapshots) {
          // Prefer the refresh containing the most *distinct sample instants*;
          // this chooses a complete bucket over a partially collected copy.
          // In a tie, prefer the refresh nearest the bucket's end time.
          const candidates=[...polls.values()].sort((a,b)=>
            b.sampleIds.size-a.sampleIds.size ||
            (a.sampleIds.size ? 0 : b.rows-a.rows) ||
            Math.abs(a.pollTime-a.end)-Math.abs(b.pollTime-b.end) ||
            b.pollTime-a.pollTime
          );
          byBucket.set(key,candidates[0]);
        }
      }
      const buckets = [...byBucket.values()].sort((a,b) => a.start-b.start || b.end-a.end);
      const known = colorsFor().map(([name]) => name);
      const extra = [...new Set(buckets.flatMap(b => [...b.groups.keys()]))]
        .filter(name => !known.some(cls => key(cls)===key(name))).sort();
      const classes = [...known.filter(name => buckets.some(b => b.groups.has(name))), ...extra];
      // All bucket values are already in average active sessions, regardless
      // of the number of native samples captured per second. Never count an
      // overlapping archive refresh twice or infer uncaptured activity.
      const timeline = [];
      for (const bucket of buckets) {
        const previous = timeline[timeline.length-1];
        const start = previous ? Math.max(previous.end,bucket.start) : bucket.start;
        if (start>=bucket.end) continue;
        const lower = new Map(); let total=0;
        for (const cls of classes) {
          lower.set(cls,total);
          total += Math.max(0,bucket.groups.get(cls)||0);
        }
        timeline.push({...bucket,start,lower,total});
      }
      // Scale to captured active sessions, not the driver-host CPU count:
      // a 24-core driver must not compress a 2-AAS MySQL workload into a
      // thin strip along the bottom of the graph.
      const ymax = Math.max(0.01, ...timeline.map(b => b.total));
      const magnitude = Math.pow(10, Math.floor(Math.log10(ymax)));
      const unit = ymax/magnitude<=2 ? 0.2 : ymax/magnitude<=5 ? 0.5 : 1;
      const step = magnitude*unit;
      const top = Math.ceil(ymax/step)*step;
      const X = t => m.left + (t-left)/(right-left)*pw;
      const Y = value => m.top + ph - value/top*ph;
      const svg = svgNode('svg', {viewBox:'0 0 '+WIDTH+' '+HEIGHT,role:'img',
        'aria-label':'Average active sessions, smooth stacked wait-class areas'});
      svg.append(svgNode('text',{x:m.left,y:19,'class':'hdb-ash-axis-title'},'Average active sessions (AAS)'));
      for (let i=0; i<=5; i++) {
        const value = top*i/5, y = Y(value);
        svg.append(svgNode('line', {x1:m.left,y1:y,x2:WIDTH-m.right,y2:y,stroke:'currentColor','stroke-opacity':'.18','stroke-dasharray':'2 5'}));
        svg.append(svgNode('text', {x:m.left-8,y:y+4,'text-anchor':'end'}, round(value)));
      }
      for (let i=0; i<=6; i++) {
        const t=left+(right-left)*i/6, x=X(t);
        svg.append(svgNode('line', {x1:x,y1:m.top,x2:x,y2:Y(0),stroke:'currentColor','stroke-opacity':'.12','stroke-dasharray':'2 5'}));
        svg.append(svgNode('text', {x:x,y:HEIGHT-11,'text-anchor':i===0?'start':i===6?'end':'middle'}, timestamp(t)));
      }
      // Match the existing Metrics chart's shaded area-and-outline style.
      // PostgreSQL uses bounded monotone interpolation; the sparser 5s
      // MySQL-family sampler connects actual bucket values directly. The
      // source AAS, wait classifications and legend colours never change.
      const centre = b => (b.start+b.end)/2;
      const monotoneSlopes = (times,values) => {
        const n=values.length,slopes=new Array(n).fill(0);
        if(n===1)return slopes;
        const span=[],delta=[];
        for(let i=0;i<n-1;i++) {
          const h=times[i+1]-times[i];
          span.push(h);
          delta.push((values[i+1]-values[i])/h);
        }
        if(n===2)return [delta[0],delta[0]];
        for(let i=1;i<n-1;i++) {
          const left=delta[i-1],right=delta[i];
          if(!left||!right||Math.sign(left)!==Math.sign(right))continue;
          const a=2*span[i]+span[i-1],b=span[i]+2*span[i-1];
          slopes[i]=(a+b)/(a/left+b/right);
        }
        const endpoint=(first,second,h1,h2) => {
          let m=((2*h1+h2)*first-h1*second)/(h1+h2);
          if(Math.sign(m)!==Math.sign(first))m=0;
          else if(Math.sign(first)!==Math.sign(second) && Math.abs(m)>3*Math.abs(first))m=3*first;
          return m;
        };
        slopes[0]=endpoint(delta[0],delta[1],span[0],span[1]);
        slopes[n-1]=endpoint(delta[n-2],delta[n-3],span[n-2],span[n-3]);
        return slopes;
      };
      const smoothValue=(values,slopes,times,i,fraction) => {
        const t=fraction,t2=t*t,t3=t2*t,h=times[i+1]-times[i];
        const value=(2*t3-3*t2+1)*values[i]+(t3-2*t2+t)*h*slopes[i]+
          (-2*t3+3*t2)*values[i+1]+(t3-t2)*h*slopes[i+1];
        // Clamp rounding and overshoot; intermediate coordinates are visual.
        return Math.max(0,Math.min(Math.max(values[i],values[i+1]),
          Math.max(Math.min(values[i],values[i+1]),value)));
      };
      const runs=[];
      let contiguous=[];
      // Sampler cadence (PG 1s, MySQL-family 5s) differs from the 15s
      // chart refresh interval. Join short display gaps for the three
      // MySQL-family engines; preserve PG's strict gap handling.
      const bucketPeriod=valid(report.bucket_secs)&&num(report.bucket_secs)>0
        ? num(report.bucket_secs) : 15;
      const maxDisplayGap=mysqlFamily ? bucketPeriod : 0;
      for(const bucket of timeline) {
        const prior=contiguous[contiguous.length-1];
        if(prior && bucket.start-prior.end>maxDisplayGap+0.000001) {
          runs.push(contiguous);contiguous=[];
        }
        contiguous.push(bucket);
      }
      if(contiguous.length)runs.push(contiguous);
      const defs=svgNode('defs'),gradients=new Map();
      classes.forEach((cls,i)=>{
        const id='hdb-ash-gradient-'+i;
        const gradient=svgNode('linearGradient',{id,x1:'0%',y1:'0%',x2:'0%',y2:'100%'});
        gradient.append(
          // Match Metrics' noticeably shaded area fill, rather than a
          // virtually solid #00FF00 block. The outline retains the exact
          // native wait-class colour used by the lower activity bars.
          svgNode('stop',{offset:'0%','stop-color':colorFor(cls),'stop-opacity':'.76'}),
          svgNode('stop',{offset:'55%','stop-color':colorFor(cls),'stop-opacity':'.42'}),
          svgNode('stop',{offset:'100%','stop-color':colorFor(cls),'stop-opacity':'.15'})
        );
        defs.append(gradient);
        gradients.set(cls,id);
      });
      svg.append(defs);
      const drawLine=(points,value,attrs) => svgNode('path',{
        d:points.map((p,i)=>(i?'L ':'M ')+X(p.time)+' '+Y(value(p))).join(' '),
        fill:'none',...attrs,'pointer-events':'none'
      });
      for(const run of runs) {
        const times=run.map(centre);
        const captured=classes.map(cls=>run.map(b=>Math.max(0,b.groups.get(cls)||0)));
        // All three five-second samplers get the same display-only moving
        // average. PostgreSQL's one-second AAS series is untouched.
        // Native AAS values and hover data are not modified.
        const values=mysqlFamily && run.length>=3
          ? captured.map(series=>series.map((value,i)=>{
              if(i===0 || i===series.length-1)return value;
              const span=times[i+1]-times[i-1];
              if(span<=0)return value;
              const neighbour=(series[i-1]*(times[i+1]-times[i])+
                series[i+1]*(times[i]-times[i-1]))/span;
              return Math.max(0,(value+neighbour)*0.5);
            }))
          : captured;
        const slopes=values.map(row=>monotoneSlopes(times,row));
        const totals=mysqlFamily
          ? run.map((bucket,i)=>values.reduce((sum,series)=>sum+series[i],0))
          : run.map(bucket=>bucket.total);
        const totalSlopes=monotoneSlopes(times,totals);
        const points=[];
        const addPoint=(time,counts)=>{
          let height=0;
          const bands=counts.map(value=>{
            const lower=height;
            height+=value;
            return [lower,height];
          });
          points.push({time,bands,total:height});
        };
        const addSample=index=>addPoint(times[index],values.map(row=>row[index]));
        addPoint(run[0].start,values.map(row=>row[0]));
        addSample(0);
        for(let i=0;i<run.length-1;i++) {
          const width=X(times[i+1])-X(times[i]);
          // Pixel interpolation only; never weight AAS by sample frequency.
          const subdivisions=Math.max(1,Math.min(9,Math.ceil(width/5)));
          for(let step=1;step<=subdivisions;step++) {
            const t=step/subdivisions;
            if(step===subdivisions) addSample(i+1);
            else {
              const counts=values.map((row,j)=>smoothValue(row,slopes[j],times,i,t));
              // Keep the total AAS on its own monotone curve: smoothing the
              // classes independently must never invent a workload spike.
              const overall=smoothValue(totals,totalSlopes,times,i,t);
              const sum=counts.reduce((total,value)=>total+value,0);
              addPoint(times[i]+t*(times[i+1]-times[i]),
                sum>0?counts.map(value=>value*overall/sum):counts);
            }
          }
        }
        addPoint(run[run.length-1].end,values.map(row=>row[row.length-1]));
        const lineFor=(index,bound) => points.map(p=>p.bands[index][bound]);
        for(let i=0;i<classes.length;i++) {
          if(!values[i].some(value=>value>0))continue;
          const upper=lineFor(i,1),lower=lineFor(i,0);
          const path=['M '+X(points[0].time)+' '+Y(upper[0])];
          for(let j=1;j<points.length;j++)path.push('L '+X(points[j].time)+' '+Y(upper[j]));
          for(let j=points.length-1;j>=0;j--)path.push('L '+X(points[j].time)+' '+Y(lower[j]));
          path.push('Z');
          const cls=classes[i];
          const band=svgNode('path',{'class':'hdb-ash-area','data-ash-group':cls,
            d:path.join(' '),fill:'url(#'+gradients.get(cls)+')'});
          band.append(svgNode('title',{},cls+' wait-class activity'));
          svg.append(band);
        }
        // Crisp colour-matched boundaries like the Metrics line outlines.
        for(let i=0;i<classes.length;i++) {
          if(!values[i].some(value=>value>0))continue;
          svg.append(drawLine(points,p=>p.bands[i][1],{
            'class':'hdb-ash-area-line','data-ash-group':classes[i],
            stroke:colorFor(classes[i]),'stroke-width':1.8,'stroke-opacity':'1',
            'stroke-linecap':'round','stroke-linejoin':'round'
          }));
        }
      }
      // Transparent per-bucket hit targets retain the exact, unsmoothed
      // values in their tooltips and preserve drag-to-select interaction.
      for (const bucket of timeline) {
        const detail=[...bucket.groups].filter(([,aas])=>aas>0)
          .map(([cls,aas])=>cls+': '+round(aas)).join(' · ');
        const hit=svgNode('rect',{'class':'hdb-ash-chart-hitbox',x:X(bucket.start),
          y:m.top,width:Math.max(0,X(bucket.end)-X(bucket.start)),height:ph,
          fill:'transparent','pointer-events':'all'});
        hit.append(svgNode('title',{},timestamp(bucket.start)+'–'+timestamp(bucket.end)+
          ' · Total: '+round(bucket.total)+' AAS'+(detail?' · '+detail:'')));
        svg.append(hit);
      }
      if (valid(report.driver_cpucount) && num(report.driver_cpucount)>0) {
        const n=num(report.driver_cpucount);
        if(n<=top) {
          svg.append(svgNode('line',{x1:m.left,y1:Y(n),x2:WIDTH-m.right,y2:Y(n),
            stroke:'var(--ash-chart-text)','stroke-opacity':'.55',
            'stroke-dasharray':'7 5','pointer-events':'none'}));
        }
        svg.append(svgNode('text',{x:WIDTH-m.right,y:19,'text-anchor':'end',
          'class':'hdb-ash-chart-reference'},
          'Driver-host CPU reference: '+n+(n>top?' (above AAS scale)':'')));
      }
      const marker=svgNode('rect',{x:0,y:m.top,width:0,height:ph,fill:'#b9c9e7',opacity:'.18','pointer-events':'none'});
      const selectStart=Object.hasOwn(selection,'pointer_begin') ? Number(selection.pointer_begin) : Object.hasOwn(selection,'begin') ? Number(selection.begin) : null;
      const selectEnd=Object.hasOwn(selection,'pointer_end') ? Number(selection.pointer_end) : Object.hasOwn(selection,'end') ? Number(selection.end) : null;
      if (selectStart!==null && selectEnd!==null) {
        const a=Math.max(left,Math.min(right,selectStart)), b=Math.max(left,Math.min(right,selectEnd));
        marker.setAttribute('x', X(Math.min(a,b)));
        marker.setAttribute('width', Math.max(0, X(Math.max(a,b))-X(Math.min(a,b))));
      }
      svg.append(marker);
      let down = null;
      const epochAt = clientX => {
        const rect=svg.getBoundingClientRect();
        const logical=(clientX-rect.left)*WIDTH/rect.width;
        return left+Math.max(0,Math.min(1,(logical-m.left)/pw))*(right-left);
      };
      svg.addEventListener('pointerdown', e => {
        if (e.button !== 0) return;
        down=epochAt(e.clientX); svg.setPointerCapture(e.pointerId);
      });
      svg.addEventListener('pointermove', e => {
        if (down===null) return;
        const end=epochAt(e.clientX);
        marker.setAttribute('x',X(Math.min(down,end)));
        marker.setAttribute('width',Math.abs(X(end)-X(down)));
      });
      svg.addEventListener('pointerup', e => {
        if (down===null) return;
        const end=epochAt(e.clientX), start=down; down=null;
        if (Math.abs(end-start)<(right-left)/350) return;
        selection={pointer_begin:Math.min(start,end),pointer_end:Math.max(start,end)};
        selectedID=null; focus='sql'; view='sql-text'; load();
      });
      svg.addEventListener('pointercancel',()=>{down=null;});
      svg.addEventListener('dblclick', e => {
        e.preventDefault();
        clearToRange();
      });
      chart.append(svg);
    }
    function barFor(row, kind, denominator) {
      const track=attr('span',{'class':'hdb-ash-activity-track','aria-hidden':'true'});
      const total=Math.max(0,num(field(row,'total'))), denom=Math.max(1,denominator);
      const segments=[];
      if (kind === 'events') {
        const cls=category(row);
        segments.push([cls,total]);
      } else {
        for (const [name] of colorsFor()) {
          const value=Math.max(0,num(field(row,name)));
          if (value>0) segments.push([name,value]);
        }
        if (!segments.length && total>0) segments.push(['Other',total]);
      }
      // The small bars are compositional: each native count retains the same
      // group colour as the chart. Absolute width uses the pane's max activity.
      const sum=segments.reduce((acc,item)=>acc+item[1],0);
      const scale=sum>total && sum>0 ? total/sum : 1;
      for(const [name,value] of segments) {
        const width=Math.min(100,Math.max(0,value*scale/denom*100));
        if(width<=0)continue;
        const slice=attr('span',{'class':'hdb-ash-activity-slice','style':'width:'+width+'%;background-color:'+colorFor(name),'title':name+': '+value});
        track.append(slice);
      }
      return track;
    }
    function paintPane(kind, rows) {
      const parent=panes[kind]; parent.replaceChildren();
      if(!Array.isArray(rows)||!rows.length) {
        parent.append(attr('p',{'class':'hdb-ash-empty'},'No ASH activity in this selection.'));
        return;
      }
      const max=Math.max(1,...rows.map(r=>num(field(r,'total'))));
      const limit=count[kind];
      for(const row of rows.slice(0,limit)) {
        const main=attr('span',{'class':'hdb-ash-row-main'});
        const id=kind==='sql' ? field(row,'queryid','digest','query_id')
          :kind==='events'?field(row,'wait_event'):field(row,'pid','processlist_id','session_id');
        let title;
        if(kind==='sql') title=id===undefined||id===''?'NULL SQL ID':String(id);
        else if(kind==='sessions') title=label(field(row,'usename','user','username'))+' · PID '+label(id);
        else title=label(id);
        main.append(attr('span',{'class':'hdb-ash-row-label','title':title},title));
        if(kind==='sql')main.append(attr('span',{'class':'hdb-ash-row-type'},label(field(row,'cmdtype','sql_type','command'))));
        if(kind==='events')main.append(attr('span',{'class':'hdb-ash-row-type'},label(field(row,'wait_event_type'))));
        const value=attr('span',{'class':'hdb-ash-row-percent'},valid(row.percent)?String(row.percent)+'%':'');
        const lower=attr('span',{'class':'hdb-ash-row-lower'});
        lower.append(barFor(row,kind,max),value);
        const button=attr('button',{'class':'hdb-ash-row','type':'button','aria-label':'View '+kind+' '+title});
        button.append(main,lower);
        const active=(kind==='sql' && focus==='sql' && String(id)===String(selectedID)) ||
          (kind==='events' && focus==='event' && String(id)===String(selectedID)) ||
          (kind==='sessions' && focus==='session' && String(id)===String(selectedID));
        if(active)button.setAttribute('aria-pressed','true');
        button.addEventListener('click',()=>selectRow(kind,row));
        parent.append(button);
      }
      if(rows.length>limit) {
        const more=attr('button',{'type':'button','class':'hdb-ash-more'},'Show more ('+(rows.length-limit)+' remaining)');
        more.addEventListener('click',()=>{count[kind]+=50;paintPane(kind,rows);});
        parent.append(more);
      }
    }
    function addText(parent,text,cls) {parent.append(attr('p',cls?{'class':cls}:{},text));}
    function addCode(parent,text) {parent.append(attr('pre',{'class':'hdb-ash-code'},text));}
    function addMetric(parent,name,value) {
      const row=attr('div',{'class':'hdb-ash-metric'});
      row.append(attr('span',{},name),attr('strong',{},label(value)));
      parent.append(row);
    }
    function addTable(parent,rows,keys) {
      const table=attr('table',{'class':'hdb-ash-stat-table'}), head=attr('thead'), tr=attr('tr');
      for(const key of keys)tr.append(attr('th',{},key.replace(/_/g,' ')));
      head.append(tr);table.append(head);
      const body=attr('tbody');
      for(const row of rows) {
        const line=attr('tr');
        for(const key of keys)line.append(attr('td',{},label(field(row,key))));
        body.append(line);
      }
      table.append(body);
      const scroll=attr('div',{'class':'hdb-ash-stat-scroll'});scroll.append(table);parent.append(scroll);
    }
    function sessionStatements(parent,mode,report) {
      const rows=report.session_sql||[];
      parent.append(attr('h4',{},'SQL statements sampled in this session'));
      if(!rows.length) {
        addText(parent,'No SQL IDs were recorded for this session. Background or idle activity may not have an associated statement.','hdb-ash-empty');
        return;
      }
      const total=num(report.session_sql_count)||rows.length;
      if(total>rows.length)addText(parent,'Showing '+rows.length+' of '+total+' SQL IDs, ordered by sampled activity.','hdb-ash-help');
      if(mode==='stats')addText(parent,
        'SQL statistics are associated with each SQL ID, not exclusively with this session. They use the recorded native statistics snapshot.',
        'hdb-ash-help');
      for(const row of rows) {
        const id=field(row,'queryid');
        const identifier=id===undefined||id===null||id===''?'NULL SQL ID':String(id);
        const block=attr('section',{'class':'hdb-ash-session-sql'});
        const title=attr('h4',{},identifier);
        block.append(title);
        addMetric(block,'Samples in session',field(row,'total'));
        const actions=attr('div',{'class':'hdb-ash-session-sql-actions'});
        for(const [tab,name] of [['sql-text','Open SQL text'],['sql-stats','Open SQL stats']]) {
          const button=attr('button',{'type':'button'},name);
          button.addEventListener('click',()=>selectRow('sql',{queryid:id},tab));
          actions.append(button);
        }
        block.append(actions);
        if(mode==='text') {
          const statement=field(row,'sql_text');
          if(statement!==undefined && statement!==null && String(statement).trim()!=='') {
            if(field(row,'text_source')==='digest_text')
              addText(block,'Normalized SQL digest text (full statement not captured):','hdb-ash-help');
            addCode(block,String(statement));
          } else addText(block,'No SQL text was captured for this SQL ID.','hdb-ash-empty');
        } else {
          const stats=(report.session_sql_stats||[]).filter(item=>String(field(item,'queryid'))===String(id));
          if(stats.length)addTable(block,stats,['statistic','total','per_exec','per_row']);
          else addText(block,id===undefined||id===null||id===''?
            'No SQL statistics are available for a NULL SQL ID.':'No native SQL statistics were recorded for this SQL ID.',
            'hdb-ash-empty');
        }
        parent.append(block);
      }
    }
    function inspect() {
      if(!current)return;
      inspector.replaceChildren();
      inspectorTitle.textContent=focus==='event'?'Wait event details':focus==='session'?'Session details':'SQL and activity details';
      const tabset=root.querySelector('.hdb-ash-tabs');
      tabset.querySelectorAll('[data-ash-dynamic]').forEach(n=>n.remove());
      if(focus==='event'||focus==='session') {
        const button=attr('button',{'type':'button','data-ash-dynamic':'1','data-ash-tab':focus},focus==='event'?'Event details':'Session details');
        button.addEventListener('click',()=>{view=focus;inspect();});tabset.prepend(button);
      }
      for(const b of tabset.querySelectorAll('button[data-ash-tab]')) {
        const active=b.dataset.ashTab===view;
        b.setAttribute('aria-pressed',active?'true':'false');
        b.setAttribute('aria-selected',active?'true':'false');
      }
      const r=current;
      if(view==='event') {
        addMetric(inspector,'Wait event',selectedID);
        const events=(r.events||[]).find(row=>String(field(row,'wait_event'))===String(selectedID));
        if(events) {
          addMetric(inspector,'Category',field(events,'wait_event_type'));
          addMetric(inspector,'Samples',field(events,'total'));
          addMetric(inspector,'DB time',label(events.percent)+'%');
        }
        const statements=r.event_sqls||[];
        inspector.append(attr('h4',{},'SQL statements waiting on this event'));
        if(statements.length) {
          for(const row of statements) {
            const block=attr('div',{'class':'hdb-ash-event-sql'});
            addMetric(block,'Samples',field(row,'total'));
            addMetric(block,'Backend',field(row,'backend_type'));
            const statement = field(row,'query','sql_text');
            if (statement !== undefined && statement !== null && String(statement).trim() !== '') {
              addCode(block,String(statement));
            } else {
              addText(block,'No SQL text was recorded for this activity'+
                (field(row,'backend_type') ? ' ('+field(row,'backend_type')+').' : '.'),
                'hdb-ash-empty');
            }
            inspector.append(block);
          }
        } else addText(inspector,'No captured SQL statements for this event.','hdb-ash-empty');
      } else if(view==='session') {
        addMetric(inspector,'Session ID',selectedID);
        const row=(r.session_details||[])[0];
        if(!row)addText(inspector,'No saved samples for this session in the selected time window.','hdb-ash-empty');
        else {
          for(const name of ['usename','application_name','pid','total','percent'])
            if(field(row,name)!==undefined)addMetric(inspector,name.replace(/_/g,' '),field(row,name));
          inspector.append(attr('h4',{},'Time spent by wait class'));
          inspector.append(barFor(row,'sessions',Math.max(1,num(field(row,'total')))));
          addTable(inspector,[row],colorsFor().map(([name])=>name).filter(name=>field(row,name)!==undefined));
        }
        sessionStatements(inspector,'text',r);
      } else if(view==='sql-text' && focus==='session') {
        sessionStatements(inspector,'text',r);
      } else if(view==='sql-stats' && focus==='session') {
        sessionStatements(inspector,'stats',r);
      } else if(view==='sql-text') {
        addMetric(inspector,'SQL ID',selection.sql_id===undefined?'Select a SQL statement':selection.sql_id===''?'NULL':selection.sql_id);
        if(r.sql_text)addCode(inspector,r.sql_text);
        else addText(inspector,selection.sql_id!==undefined?'No SQL text was captured for this statement.':'Select a SQL statement to see its captured text.','hdb-ash-empty');
      } else if(view==='sql-io') {
        const rows=(r.sql_io && r.sql_io.length) ? r.sql_io :
          (r.events||[]).filter(row=>key(category(row))==='io');
        inspector.append(attr('h4',{},'Recorded I/O waits'));
        if(!rows.length)addText(inspector,'No captured I/O waits for this selection.','hdb-ash-empty');
        else addTable(inspector,rows,['wait_event','total']);
      } else if(view==='sql-stats') {
        const rows=r.sql_statistics&&r.sql_statistics.length?r.sql_statistics:[];
        if(rows.length)addTable(inspector,rows,['statistic','total','per_exec','per_row']);
        else addText(inspector,selection.sql_id!==undefined?'No SQL statistics snapshot was captured for this statement.':'Select a SQL statement to view its captured statistics.','hdb-ash-empty');
      } else if(view==='cpu') {
        addMetric(inspector,'Driver-host CPU reference',r.driver_cpucount);
        addMetric(inspector,'Captured ASH samples',r.sample_count);
        addMetric(inspector,'Selected ASH samples',r.selected_sample_count);
        addText(inspector,'This is the benchmark driver-host CPU reference from the Desktop metrics path, not database host utilisation.','hdb-ash-help');
        const cpu=(r.events||[]).filter(row=>key(category(row))==='cpu'||key(category(row))==='bcpu');
        if(cpu.length)addTable(inspector,cpu,['wait_event','total','percent']);
      }
    }
    const formatStatus = report => String(report.state||'saved')+' · '+label(report.sample_count)+' captured samples'+
      (report.error?' · '+report.error:'')+(report.message?' · '+report.message:'');
    const detailFields = ['sql_text','sql_io','sql_stats','sql_statistics','sql_overtime',
      'event_sqls','session_details','session_sql','session_sql_stats','session_sql_count'];
    const hasDetail = () => ['sql_id','event_id','session_id'].some(key=>Object.prototype.hasOwnProperty.call(selection,key));
    async function load(forceSummary=false) {
      if(timer)clearTimeout(timer);
      if(controller)controller.abort();
      const request=new AbortController();controller=request;
      const thisCall=++generation;
      const url=new URL(source);
      const parameter={begin:'begin',end:'end',pointer_begin:'pointerbegin',pointer_end:'pointerend',sql_id:'sqlid',event_id:'eventid',session_id:'sessionid'};
      const detail = !forceSummary && current && hasDetail();
      if (forceSummary) {
        // Live chart refresh while a SQL/event/session is selected. Restore
        // only the displayed Job window, not the selected drilldown query.
        if (current && ['begin','end','pointer_begin','pointer_end'].some(key=>Object.prototype.hasOwnProperty.call(selection,key))) {
          url.searchParams.set('begin',String(current.begin));
          url.searchParams.set('end',String(current.end));
        }
      } else if (detail) {
        // The summary already resolved chart pointer selection to native
        // bounds. Do not reselect from an empty detail-only chart.
        url.searchParams.set('detailonly','1');
        url.searchParams.set('begin',String(current.begin));
        url.searchParams.set('end',String(current.end));
        for (const key of ['sql_id','event_id','session_id'])
          if (Object.prototype.hasOwnProperty.call(selection,key))
            url.searchParams.set(parameter[key],String(selection[key]));
      } else {
        for(const [key,value] of Object.entries(selection))url.searchParams.set(parameter[key],String(value));
      }
      const deadline=setTimeout(()=>request.abort(),30000);
      try {
        const reply=await fetch(url,{credentials:'same-origin',cache:'no-store',signal:request.signal});
        const report=await reply.json();
        if(thisCall!==generation)return;
        if(!reply.ok || (!report.available && report.error))throw new Error(report.error||'ASH report request failed.');
        if (detail) renderDetail(report);
        else if (forceSummary && current && hasDetail() && report.available) {
          // Preserve the existing selected-item detail while refreshing the
          // chart and summary counts in a running benchmark.
          for (const field of detailFields)
            report[field] = current[field];
          render(report);
        } else render(report);
      } catch(error) {
        if(thisCall!==generation)return;
        const message = error.name==='AbortError'?'ASH request timed out.':String(error.message);
        status.textContent=message;
        inspector.replaceChildren(attr('p',{'class':'hdb-ash-empty'},'Unable to load ASH details: '+message));
      } finally {clearTimeout(deadline);}
    }
    function renderDetail(report) {
      if (!current || !report.available) {
        status.textContent = report.message || 'ASH details could not be loaded.';
        return;
      }
      // Do not replace the summary chart, rows or percentages with the
      // selected SQL/event/session subset's own denominators.
      for(const field of detailFields)
        current[field] = Object.prototype.hasOwnProperty.call(report,field) ? report[field] :
          field === 'sql_text' ? '' : field === 'session_sql_count' ? 0 : [];
      status.textContent = formatStatus(current);
      for(const kind of ['sql','events','sessions'])paintPane(kind,current[kind]);
      inspect();
      if(current.state==='running')timer=setTimeout(()=>load(true),15000);
    }
    function render(report) {
      current=report;
      const available=!!report.available;
      root.classList.toggle('hdb-ash-unavailable',!available);
      status.textContent=available ? formatStatus(report) :
        (report.message||'ASH was not collected for this Job.');
      if(!available) {
        chart.replaceChildren();legend.replaceChildren();bounds.textContent='';
        workspace.hidden=true;range.hidden=true;limitations.replaceChildren();return;
      }
      workspace.hidden=false;range.hidden=false;
      syncRange(report);
      const selecting=Object.hasOwn(selection,'pointer_begin')||Object.hasOwn(selection,'begin');
      bounds.textContent=selecting&&valid(report.begin)&&valid(report.end) ?
        'Selected · '+stampLong(report.begin)+' — '+stampLong(report.end) : '';
      paintChart(report);
      paintPane('sql',report.sql);
      paintPane('events',report.events);
      paintPane('sessions',report.sessions);
      inspect();
      limitations.replaceChildren();
      for(const message of report.limitations||[])
        limitations.append(attr('li',{},message));
      if(report.state==='running')timer=setTimeout(()=>load(hasDetail()),15000);
    }
    root.querySelector('[data-ash-range-apply]').addEventListener('click',()=>{
      const begin=Date.parse(rangeBegin.value)/1000, end=Date.parse(rangeEnd.value)/1000;
      if (!current || !Number.isFinite(begin) || !Number.isFinite(end) || begin>end ||
          begin < Number(current.captured_begin) || end > Number(current.captured_end)) {
        rangeError.textContent='Choose a valid time window within this benchmark Job.';
        return;
      }
      rangeError.textContent='';
      selection={begin,end};
      focus='sql';selectedID=null;view='sql-text';load();
    });
    root.querySelector('[data-ash-range-reset]').addEventListener('click',clearToRange);
    for(const button of root.querySelectorAll('[data-ash-tab]'))button.addEventListener('click',()=>{view=button.dataset.ashTab;inspect();});
    window.addEventListener('pagehide',()=>{if(timer)clearTimeout(timer);if(controller)controller.abort();});
    load();
  }
  function start(){document.querySelectorAll('[data-hdb-ash]').forEach(mount);}
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',start,{once:true});
  else start();
})();