





function build_dag(data) {



// initialize panning, zooming
const zoom = d3
  .zoom()
  .on("zoom", () => g.attr("transform", d3.event?.transform));

// append the svg object to the body of the page
// assigns width and height
// activates zoom/pan and tooltips
const svg = d3
  .select("body")
  .select("#cte_dag")
  .html("")
  .append("svg")
  .call(zoom);
// .call(tip)

// append group element
const g = svg.append("g");

  // declare a dag layout
  const dag = d3.dagStratify()(data);
  const nodeRadius = 20;
  const layout = d3
    .sugiyama() // base layout
    .decross(d3.decrossOpt()) // minimize number of crossings
    .nodeSize((node) => [(node ? 10.6 : 0.25) * nodeRadius , 3 * nodeRadius]); // set node size instead of constraining to fit
  const { width, height } = layout(dag);

  // --------------------------------
  // This code only handles rendering
  // --------------------------------
  const svgSelection = d3.select("svg");
  svgSelection.attr("viewBox", [0, 0, width, height].join(" "));


  const steps = dag.size();
  const interp = d3.interpolateRainbow;
  const colorMap = new Map();
  for (const [i, node] of dag.idescendants().entries()) {
    colorMap.set(node.data.id, interp(i / steps));
  }

  // How to draw edges
  const line = d3
    .line()
    .curve(d3.curveCatmullRom)
    .x((d) => d.x)
    .y((d) => d.y);

  // Plot edges
  svgSelection
    .append("g")
    .selectAll("path")
    .data(dag.links())
    .enter()
    .append("path")
    .attr("d", ({ points }) => line(points))
    .attr("fill", "none")
    .attr("stroke-width", 3)
    .attr("stroke", "#82b1ff ");

  // Select nodes
  const nodes = svgSelection
    .append("g")
    .selectAll("g")
    .data(dag.descendants())
    .enter()
    .append("g")
    .attr("transform", ({ x, y }) => {
      return `translate(${x}, ${y})`
    });

  // Plot node circles
  nodes
    .append("circle")
    .attr("r", nodeRadius)
    .attr("fill", "#82b1ff")
    .attr("stroke","#82b1ff ")
    .attr("opacity","30%")
    ;


  // Add text to nodes
  nodes
    .append("text")
    .text((d) => d.data.id)
    .on("click", (e)=>explore_cte(e))
    .attr("font-weight", "bold")
    .attr("font-family", "sans-serif")
    .attr("font_size","20px")
    .attr("text-anchor", "middle")
    .attr("alignment-baseline", "middle")
    .attr("fill", "#F8F8F2");

  function explore_cte(e) {
    const sql_model = e.target.__data__.data
    const cte = sql_model.id
    const sql = sql_model.sql
    
    d3.select("body").select("#cte_name").text("/ "+cte)
    d3.select("body").select("#cte_code_block").select("#cte_code").text(sql)
    document.getElementById('editor').style.fontSize='12px';
    console.log(sql_model.cols)
 

    var tr = d3.select("#cte_col")
     .html("")
     .selectAll("tr")
     .data(sql_model.cols)
     .enter().append("tr");

    tr.selectAll("td")
     .data(function(d, i) { return Object.values(d); })
     .enter().append("td")
       .html(function(d) { return d; });


    var editor = ace.edit("editor");
      editor.setValue(sql,-1)
      editor.insert("---------------"+ cte +"---------------\n")


  } 

}

function startNewCode() {

  var editor = ace.edit("editor2");
  editor.setValue("---------------ENTER YOUR SQL CODE---------------\n",-1)
  editor.setReadOnly(false);

  var new_code_form = d3.select("#model_info")
  .text("")
  .append("form")
  .attr("method","POST")
  .attr("action", "/submite_new")

  form_row = new_code_form.append("div").attr("class","row")

  form_row.append("div").attr("class","col s4")
  .append("button")
  .text("parse")
  .attr("class","waves-effect waves-light btn")
  .attr("type", "submit")
  
  file_name_col = form_row.append("div").attr("class","col s7")
  
 
  file_name_col.append("input")
  .attr("id","filename")
  .attr("type","text")
  .attr("name","filename")
  .attr("placeholder","file name")
  .attr("required", true)
  
 

  new_code_form.append("input")
  .attr("id","sql_pay_load")
  .attr("type","hidden")
  .attr("name","sql_code")

  editor.session.on('change', function(){
    code = editor.getValue()
    d3.select("#sql_pay_load").attr("value", code)  
  } )

 ;
}

function getCode(){
  var editor = ace.edit("editor2");
  code = editor.getValue()

  d3.select("#sql_pay_load").attr("value", code)
}