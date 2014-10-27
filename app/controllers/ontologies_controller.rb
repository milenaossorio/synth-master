class OntologiesController < ApplicationController
  
  def index
    @ontologies = SYMPH::Ontology.find_all
  end
    
  # GET /ontologies/new
  # GET /ontologies/new.xml
  def new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @ontology }
    end
  end

  # POST /ontologies
  # POST /ontologies.xml
  def create
    @ontology = SYMPH::Ontology.save(params[:ontology])
        
    respond_to do |format|
      if @ontology
        flash[:notice] = 'Ontology was successfully created.'
      else
        flash[:notice] = 'Failed on create ontology.'
      end
      format.html { redirect_to :action => :edit, :id => @ontology }
      format.xml  { render :xml => @ontology, :status => :created, :location => @ontology }
    end
  end

  # GET /ontology/1/edit
  def edit
    @ontology = SYMPH::Ontology.find(params[:id])
  end
  
  # PUT /ontology/1
  # PUT /ontology/1.xml
  def update
    @ontology = SYMPH::Ontology.find(params[:id])

    respond_to do |format|
      if @ontology.update_attributes(params[:ontology])
        flash[:notice] = 'Ontology was successfully updated.'
        format.html { redirect_to(ontologies_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @ontology.errors, :status => :unprocessable_entity }
      end
    end
	
  end

  # DELETE /ontologies/1
  # DELETE /ontologies/1.xml
  def destroy
    
    @ontology = SYMPH::Ontology.find(params[:id])
    @ontology.disable
    @ontology.destroy
     
    respond_to do |format|
      format.html { redirect_to :action => :index }
      format.xml  { head :ok }
    end
  end
  
  def activate_ontology
    @ontology = SYMPH::Ontology.find(params[:id])
    @ontology.activate
    
    respond_to do |format|
      flash[:notice] = 'Ontology was successfully activated.'
      format.html { redirect_to :action => :edit, :id => @ontology }
      format.xml  { head :ok }
    end
  end
 
  def disable_ontology
    @ontology = SYMPH::Ontology.find(params[:id])
    @ontology.disable
    
    respond_to do |format|
      flash[:notice] = 'Ontology was successfully disabled.'
      format.html { redirect_to :action => :edit, :id => @ontology }
      format.xml  { head :ok }
    end
  end
  
  # GET /ontologies/wizard/id:/[^\/]+/
  def wizard
    param = params[:url] || 'http://swrc.ontoware.org/ontology'
    domain_classes = RDFS::Class.domain_classes.
      map{|value| ActiveRDF::Namespace.localname(value.uri) if value.uri.index(param) == 0}.compact.sort
    wizard = []
    flowTree = class_step("0.0.0", wizard, domain_classes, "swrc")
    breadthFirstSearch(flowTree, wizard)
    render :json => {:windows=>wizard}
  end
    
  def breadthFirstSearch(flowTree, wizard)
    aux = []
    if flowTree
      aux.push(flowTree)
    while aux.cont > 0
      wizard.push(aux[0][:value])
      aux[0][:children].each {|child|
        aux.push(child)
      }
      aux.delete(0)
    end
  end  
  
  def class_step(previousId, wizard, classes, prefix) # 4, 27,...
    index = -1
    currentId = previousId + ".0"
    m = {:id => currentId, :type => 'select', :title => "What do you want to show from #{prefix} ontology?", 
      :message => 'Class', :options => []}
    m[:options] = classes.map{|className| {:key=>(index += 1), :text=>className, :next=>currentId + "." + index.to_s}}
    flowTree[:value] = m
    
    class_next_step(currentId, wizard, domain_classes, flowTree);
    return flowTree
    #wizard.push(m);
  end
  
  def class_next_step(previousId, wizard, classes, fatherFlowTree) #5, 28, ...
    index = -1
    aux = []
    classes.each{ |name|
      currentId = (previousId + "." + (index += 1).to_s)
      m = {:id => currentId, :type => 'radio', :title => 'What do you want to do?', 
        :message => '',
        :options => [
          {:key => 0, :text => "Show a list of #{name}(s) to be chosen", :next => currentId + ".0"},
          {:key => 1, :text => "Show the detail of a(n) #{name}", :next => currentId + ".1"},
          {:key => 2, :text => "Define a computation using a(n) #{name}", :next => currentId + ".2"}
          ]}
      child = {:value => m}
      fatherFlowTree[:children].push(child)
      example_list(x[:id], wizard, x[:className], getExamplesFor(x[:className], 3, 'label'), child)
      example_detail(x[:id], wizard, x[:className], getDatatypeProperties(x[:className]), child)
      
    #  wizard.push(m);
    #  aux.push({:id => currentId, :className => name})
    }
#    aux.each {|x| 
#      example_list(x[:id], wizard, x[:className], getExamplesFor(x[:className], 3, 'label'))
#      example_detail(x[:id], wizard, x[:className], getDatatypeProperties(x[:className]))
#      }
=begin
    aux.each {|x|
      example_list_choose_one_more_attributes_question(x[:id] + ".0", wizard, x[:className], getExamplesFor(x[:className], 3, 'label'))
      example_list_choose_more_than_one_more_attributes_question(x[:id] + ".0", wizard, x[:className], getExamplesFor(x[:className], 3, 'label'))
      choose_attributes_types_detail(x[:id] + ".1", wizard, x[:className])
      example_detail_navigation_to_other_screen_question(x[:id] + ".1", wizard, x[:className])
      
    }
=end    
   
  end
  
  def getExamplesFor(className, cant, *props) 
    return ['Posters Display', 'Demo: Adapting a Map Query Interface...', 'Demo: Blognoon: Exploring a Topic in...']
  end
  
  def getDatatypeProperties(className)
    return ["label", "summary", "Documents"]
  end
  
  def example_list(previousId, wizard, className, examples) # 6, 29, ...
    currentId = previousId.to_s + ".0"
    m = {:id => currentId, :title => "", :type => "radioDetail", :message => className,
            :messageOptions => "Do you want to choose",
            :options => [
              {:key => 0, :text => "one #{className}?", :next => currentId + ".0"},
              {:key => 1, :text => "more than one #{className}?", :next => currentId + ".1"} 
            ],
            :details =>
            [
              [
                  [{:type => "text", :msg => examples[0]}],
                  [{:type => "text", :msg => examples[1]}],
                  [{:type => "text", :msg => examples[2]}]
              ],
              [
                  [{:type => "img", :msg => '/assets/checkbox-checked.png'},{:type => "text", :msg => examples[0]}],
                  [{:type => "img", :msg => '/assets/checkbox.png'},{:type => "text", :msg => examples[1]}],
                  [{:type => "img", :msg => '/assets/checkbox-checked.png'},{:type => "text", :msg => examples[2]}]
              ]
            ]
        }
  end
  
  def example_detail(previousId, wizard, className, datatypeProperties) # 15, 42, ...
    currentId = previousId.to_s + ".1"
    m = {:id => currentId, :title => "#{className} detail", :type => "yesNoDetail",
            :messageOptions => "Do you want to show other attributes of a(n) #{className} in the detail view?",
            :datatypeProperties => datatypeProperties,
            :example => className,
            :options => [
              {:key => 0, :text => "Yes", :next => currentId + ".0"},{:key => 1, :text => "No", :next => currentId + ".1"} 
            ]
        }
  end
  
  def example_list_choose_one_more_attributes_question(previousId, wizard, className, examples) #30, 32, ...
    currentId = previousId.to_s + ".0"
    m = {
            :id => currentId, :title => "", :type => "infoWithOptions", :message => "#{className}s",
            :messageOptions => "Do you want to show other attributes of an #{className} than those shown in the example?",
            :options => [
              {:key => 0, :text => "Yes", :next => currentId + ".0"},{:key => 1, :text => "No", :next => currentId + ".1"}
            ],
            :details => [
                    [{:type => "text", :msg => examples[0]}],
                    [{:type => "text", :msg => examples[1]}],
                    [{:type => "text", :msg => examples[2]}]
                  ]
    }
    wizard.push(m)
  end
  
  def example_list_choose_more_than_one_more_attributes_question(previousId, wizard, className, examples) #31, 33, ...
    currentId = previousId.to_s + ".1"
    m = {
            :id => currentId, :title => "", :type => "infoWithOptions", :message => "#{className}s",
            :messageOptions => "Do you want to show other attributes of an #{className} than those shown in the example?",
            :options => [
              {:key => 0, :text => "Yes", :next => previousId.to_s + ".0.0"},{:key => 1, :text => "No", :next => previousId.to_s + ".0.1"}
            ],
            :details => [
                    [{:type => "img", :msg => "/assets/checkbox-checked.png"},{:type => "text", :msg => examples[0]}],
                    [{:type => "img", :msg => "/assets/checkbox.png"},{:type => "text", :msg => examples[1]}],
                    [{:type => "img", :msg => "/assets/checkbox-checked.png"},{:type => "text", :msg => examples[2]}]
                  ]
    }
    wizard.push(m)
  end 
  
  def choose_attributes_types_detail(previousId, wizard, className) #16
    currentId = previousId.to_s + ".0"
      m = {      
            :id => currentId, :title => "", :type => "radio",
            :message => "Which type of attributes you want to show in the #{className} detail?",
            :options => [
              {:key => 0, :text => "Direct attributes of an #{className}", :next => currentId + ".0"},
              {:key => 1, :text => "Attributes of other classes related to #{className}", :next => currentId + ".1"},
              {:key => 2, :text => "Computed Attributes", :next => currentId + ".2"} 
            ]
      } 
      wizard.push(m)   
  end
  
  def example_detail_navigation_to_other_screen_question(previousId, wizard, className) #23
    currentId = previousId.to_s + ".1"
    m = {
          :id => currentId,
          :title => "",
          :type => "loopDetail",
          :message => "#{className} Detail",
          :messageOptions => "Do you want to choose anything to navigate to other screen?",
          :example => "#{className}",
          :options => [
              {:key => 0, :text => "Yes", :next => currentId + ".0" },
              {:key => 1, :text => "No", :next => currentId + ".1"}
            ]
          }
    wizard.push(m)    
  end     
  
  def choose_attributes_types_list(previousId, wizard, className) #7
    currentId = previousId.to_s + ".0"
    m = {
          :id => currentId, :title => "", :type => "radio", 
          :message => "Which type of attributes you want to show in the #{className} list?",
          :options => [
              {:key => 0, :text => "Direct attributes of a(n) #{className}", :next => currentId + ".0"},
              {:key => 1, :text => "Attributes of other classes related to #{className}", :next => currentId + ".1"},
              {:key => 2, :text => "Computed Attributes", :next => currentId + ".2"} 
            ]
    }
    wizard.push(m)
  end
  end