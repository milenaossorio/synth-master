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
    #flowTree = class_step("0.0.0", domain_classes, "swrc")
    
    #breadthFirstSearch(flowTree, wizard)
    
    wizard = getExamplesFor("ArgumentativeDocument", 3)
    #wizard = getExamplesFor("AccommodationPlace", 3)
    
   # wizard = getDatatypeProperties("AcademicEvent", true)
    
    render :json => {:windows=>wizard}
  end
    
  def breadthFirstSearch(flowTree, wizard)
    aux = []
    if flowTree != nil
      aux.push(flowTree)
    end
    while aux.count > 0
      wizard.push(aux[0][:value])
      aux[0][:children].each {|child|
        aux.push(child)
      }
      aux.delete_at(0)
    end      
  end  
  
  def class_step(previousId, classes, prefix) # 4, 27,...
    index = -1
    currentId = previousId + ".0"
    m = {:id => currentId, :type => 'select', :title => "What do you want to show from #{prefix} ontology?", 
      :message => 'Class', :options => []}
    m[:options] = classes.map{|className| {:key=>(index += 1), :text=>className, :next=>currentId + "." + index.to_s}}
    flowTree = {:value => m, :children => []}
    
    class_next_step(currentId, classes, flowTree);
    return flowTree
    #wizard.push(m);
  end
  
  def class_next_step(previousId, classes, fatherFlowTree) #5, 28, ...
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
      child = {:value => m, :children => []}
      fatherFlowTree[:children].push(child)
      example_list(currentId, name, getExamplesFor(name, 3, 'label'), child)
      example_detail(currentId, name, getDatatypeProperties(name, false), child)
      
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
    
    puts 'begin***************************'
    
   # from_label = RDFS::Class.find_by.rdfs::label(:regex => (/#{className}/)).execute.first
    
    className = RDFS::Class.find_all().select{|x| ActiveRDF::Namespace.localname(x.uri) == className}.first
    resources = className.nil? ? [] : ActiveRDF::ObjectManager.construct_class(className).find_all
  
 
      result = resources[0,10].map{|resource| 
      resource.rdfs::label.empty? ? "compacturi: #{resource.compact_uri}" : "label: #{resource.rdfs::label.first}"
        }.uniq.compact[0, cant]
    (result.length...cant).each do result.push("No more example") end                   
    return result
    #return ['Posters Display', 'Demo: Adapting a Map Query Interface...', 'Demo: Blognoon: Exploring a Topic in...']
  end
  
  def getDatatypeProperties(className, isFirstSet)
=begin 
    className = RDFS::Class.find_all().select{|x| ActiveRDF::Namespace.localname(x.uri) == className}.first
    datatypeProps = className.nil? ? [] : ActiveRDF::ObjectManager.construct_class(className).direct_predicates(distinct = true)
    
    result = datatypeProps.map{|prop|
      prop.rdfs::label.empty? ? "compacturi: #{prop.compact_uri}" : "label: #{prop.rdfs::label.first}"
      }
      
      return result
=end
    if (isFirstSet)
      return ["label", "start", "end", "summary"]
    else
      return ["label", "summary", "Documents"]
    end

  

  end
  
  def getRelatedCollections(className)
    return ["Article", "Book", "Conference", "Event", "Person", "Document"]
  end
  
  def example_list(previousId, className, examples, fatherFlowTree) # 6, 29, ...
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
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
    example_list_choose_one_more_attributes_question(currentId, className, getExamplesFor(className, 3, 'label'), child)
    example_list_choose_more_than_one_more_attributes_question(currentId, className, getExamplesFor(className, 3, 'label'), child)
    
  end
  
  def example_detail(previousId, className, datatypeProperties, fatherFlowTree) # 15, 42, ...
    currentId = previousId.to_s + ".1"
    m = {:id => currentId, :title => "#{className} detail", :type => "yesNoDetail",
            :messageOptions => "Do you want to show other attributes of a(n) #{className} in the detail view?",
            :datatypeProperties => datatypeProperties,
            :example => className,
            :options => [
              {:key => 0, :text => "Yes", :next => currentId + ".0"},{:key => 1, :text => "No", :next => currentId + ".1"} 
            ]
        }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
    choose_attributes_types_detail(currentId, className, child)
    example_detail_navigation_to_other_screen_question(currentId, className, child)
    
  end
  
  def example_list_choose_one_more_attributes_question(previousId, className, examples, fatherFlowTree) #30, 32, ...
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
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
    choose_attributes_types_list(currentId, className, child)
    choose_examples_list_navigation_question(currentId, className, child) 
    
  end
  
  def example_list_choose_more_than_one_more_attributes_question(previousId, className, examples, fatherFlowTree) #31, 33, ...
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
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
  end 
  
  def choose_attributes_types_detail(previousId, className, fatherFlowTree) #16
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
      child = {:value => m, :children => []}
      fatherFlowTree[:children].push(child)
      
      datatype_properties_selection_detail(currentId, className, getDatatypeProperties(className, true), child)
      related_collection_detail(currentId, className, getRelatedCollections(className), child)
      computed_attribute_detail(currentId, className, child)
      
  end
  
  def example_detail_navigation_to_other_screen_question(previousId, className, fatherFlowTree) #23
    currentId = previousId.to_s + ".1"
    m = {
          :id => currentId,
          :title => "",
          :type => "loopDetail",
          :message => "#{className} Detail",
          :messageOptions => "Do you want to choose anything to navigate to other screen?",
          :example => className,
          :options => [
              {:key => 0, :text => "Yes", :next => currentId + ".0" },
              {:key => 1, :text => "No", :next => currentId + ".1"}
            ]
          }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
    
    choose_attribute_to_navigate_detail(currentId, className, child)
    finish_app(currentId, className, child)    
    
  end     
  
  def choose_attributes_types_list(previousId, className, fatherFlowTree) #7
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
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
    
    datatype_properties_selection_list(currentId, className, getDatatypeProperties(className, true), child)
    related_collection_list(currentId, className, getRelatedCollections(className), child)
    computed_attribute_list(currentId, className, child)
    
  end
 
  def choose_examples_list_navigation_question(previousId, className, fatherFlowTree) #24
    currentId = previousId.to_s + ".1"
    m = {
            :id => currentId, :title => "", :type => "loop", :message => "", :message1 => "#{className} List",
            :messageOptions => "Do you want to choose anything to navigate to other screen?",
            :example => className,
            :options => [
              {:key => 0, :text => "Yes", :next => currentId + ".0"},
              {:key => 1, :text => "No", :next => previousId[0, previousId.length-4] + ".1.1.1"}
            ]
        }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
    
    choose_attribute_to_navigate_list(currentId, className, child)
    
  end
  
  def datatype_properties_selection_detail(previousId, className, datatypeProperties, fatherFlowTree) #17
    currentId = previousId.to_s + ".0"
    m = {
            :id => currentId, :title => "Following this example which attributes you want to show in the #{className} detail",
            :type => "checkboxForDetail", :message => "Add #{className} properties", :example => className,
            :datatypeProperties => datatypeProperties,
            :options =>  [  
                  {:key => 0, :next => previousId + ".1.0.0.0"}
                ],
            :message1 => "Selected properties"
        }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
    
  end
  
  def related_collection_detail(previousId, className, relatedCollections, fatherFlowTree) #19
    currentId = previousId.to_s + ".1"
    m = {
          :id => currentId, :title => "Select what you want to show", :type => "select",
          :message => "#{className}'s \t related collections",
          :options => [
              {:key => 0, :text => relatedCollections[0], :next => currentId + ".0"},
              {:key => 1, :text => relatedCollections[1], :next => currentId + ".0"}, 
              {:key => 2, :text => relatedCollections[2], :next => currentId + ".0"}, 
              {:key => 3, :text => relatedCollections[3], :next => currentId + ".0"}, 
              {:key => 4, :text => relatedCollections[4], :next => currentId + ".0"},
              {:key => 5, :text => relatedCollections[5], :next => currentId + ".0"} 
          ]
        }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
    
    suggest_paths_detail(currentId, className, child) #20
  
  end
  
  def computed_attribute_detail(previousId, className, fatherFlowTree) #22
    currentId = previousId.to_s + ".2"
    m = {
            :id => currentId, :title => "Computed attribute", :type => "computedAttribute", :needNextProcessing => true,
            :message => "New attribute", :message1 => "Selected properties", :example => className,
            :options => [
              {:key => 0, :next => previousId + ".1.0.0.0"} 
            ]
        }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
        
  end
  
  def choose_attribute_to_navigate_detail(previousId, className, fatherFlowTree) #25
    currentId = previousId.to_s + ".0"
    m = {
            :id => currentId, :title => "Select where one should click to choose an #{className}",
            :type => "attributeForChoosingForDetail", :needNextProcessing => true, :message => "#{className} Detail",
            :originalModal => "You clicked on the {0}. Do you want to use the {0} to choose a(n) #{className}",
            :modal => "You clicked on the {0}. Do you want to use the {0} to choose a(n) #{className}",
            :example => className,
            :options => [
              {:key => 0, :next => ".0.0.0"} 
             ]
          }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
    
  end
  
  def finish_app(previousId, className, fatherFlowTree) #26
    currentId = previousId.to_s + ".1"
    m = {
            :id => currentId, :title => "What do you want to do?", :type => "radio", :message => "",
            :options => [
              {:key => 0, :text => "Go to the pages index", :next => 26},
              {:key => 1, :text => "Finish the application definition", :next => 26} 
            ]
        }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
    
  end
  
  def datatype_properties_selection_list(previousId, className, datatypeProperties, fatherFlowTree) #9
    currentId = previousId.to_s + ".0"
    m = {
            :id => currentId, :title => "Following this example which attributes you want to show in the #{className} list",
            :type => "checkbox", :message => "Add #{className} properties", :example => className,
            :datatypeProperties => datatypeProperties,
            :options =>  [  
                  {:key => 0, :next => previousId + ".1.0.0.0"}
                ],
            :message1 => "Selected properties"
        }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
        
  end
  
  def related_collection_list(previousId, className, relatedCollections, fatherFlowTree) #10
    currentId = previousId.to_s + ".1"
    m = {
            :id => currentId, :title => "Select what you want to show", :type => "select", :message => "#{className}'s \t related collections",
            :options => [
              {:key => 0, :text => relatedCollections[0], :next => currentId + ".0"}, 
              {:key => 1, :text => relatedCollections[1], :next => currentId + ".0"}, 
              {:key => 2, :text => relatedCollections[2], :next => currentId + ".0"}, 
              {:key => 3, :text => relatedCollections[3], :next => currentId + ".0"}, 
              {:key => 4, :text => relatedCollections[4], :next => currentId + ".0"},
              {:key => 5, :text => relatedCollections[5], :next => currentId + ".0"} 
            ]
         }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
    
    suggest_paths(currentId, className, child)
    
  end
  
  def computed_attribute_list(previousId, className, fatherFlowTree) #13
    currentId = previousId.to_s + ".2"
    m = {
            :id => currentId, :title => "Computed attribute", :type => "computedAttribute", 
            :message => "New attribute", :message1 => "Selected properties", :example => className,
            :options => [
              {:key => 0, :next => previousId + ".1.0.0.0"} 
             ]
        }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
    
  end
  
  def choose_attribute_to_navigate_list(previousId, className, fatherFlowTree) #14
    currentId = previousId.to_s + ".0"
    m = {
            :id => currentId, :title => "Select where one should click to choose a(n) #{className}", 
            :type => "attributeForChoosing", :message => "Events", :example => className, 
            :originalModal => "You clicked on the {0}. Do you want to use the {0} to choose a(n) #{className}",
            :modal => "You clicked on the {0}. Do you want to use the {0} to choose a(n) #{className}",
            :options => [
              {:key => 0, :next => ".0.0.0"} 
             ]
        }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
    
  end
          
  def suggest_paths(previousId, className, fatherFlowTree) #11
    currentId = previousId.to_s + ".0"
    m = {
            :id => currentId, :title => "Select the path", :type => "paths", :message => "Suggested paths",
            :paths => [
                  {:key => 0, :pathItems => ["Event", "Document", "Person"], :examples => ["Event1 - hasOpeningDocument:presenter - Milena",
                                                  "Event1 - hasOpeningDocument:author - João",
                                                  "Event2 - hasClosingDocument:advisor - Schawbe"]},
                  {:key => 1, :pathItems => ["Event", "Person"], :examples => ["Event1 - organizer - Tim Berners Lee"]}
                   ],
            :options => [
                    {:key => 0, :next => currentId + ".0"}, {:key => 1, :next => currentId + ".0"}
                   ]
          }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
    
    choose_relations_of_path(currentId, className, child) #12
    
  end
  
  def choose_relations_of_path(previousId, className, fatherFlowTree) #12
    currentId = previousId.to_s + ".0"
    m = {
            :id => currentId, :title => "Select the relationships", :type => "path",
            :message => "Suggested path",
            :paths => [
                  {:key => 0, :pathItems => ["Event", "Document", "Person"], :examples => ["Event1 - hasOpeningDocument:presenter - Milena",
                                                  "Event1 - hasOpeningDocument:author - João",
                                                  "Event2 - hasClosingDocument:advisor - Schawbe"]},
                  {:key => 1, :pathItems => ["Event", "Person"], :examples => ["Event1 - organizer - Tim Berners Lee"]}
                 ],
            :options => [
                    {:key => 0, :next => currentId + ".0"}, {:key => 1, :next => currentId + ".0"}
                   ]
        }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
    more_attributes_question_list(currentId, className, child) #8
    
  end
  
  def more_attributes_question_list(previousId, className, fatherFlowTree) #8
    currentId = previousId.to_s + ".0"
    m = {
            :id => currentId, :title => "", :type => "radioSelectedProperties",
            :message => "Do you want to show more attributes in the #{className} list? Which type?",
            :example => className,
            :options => [
              {:key => 0, :text => "Direct attributes of an #{className}", :next => previousId[0, previousId.length-6] + ".0"},
              {:key => 1, :text => "Attributes of other classes related to #{className}", :next => previousId[0, previousId.length-4]},
              {:key => 2, :text => "Computed Attributes", :next => previousId[0, previousId.length-6] + ".2"},
              {:key => 3, :text => "No more", :next => previousId[0, previousId.length-8] + ".1"}
            ]
        }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
  
  end
  
  def suggest_paths_detail(previousId, className, fatherFlowTree) #20
    currentId = previousId.to_s + ".0"
    m = {
            :id => currentId, :title => "Select the path", :type => "paths",
            :message => "Suggested paths",
            :paths => [
                  {:key => 0, :pathItems => ["Event", "Document", "Person"], :examples => ["Event1 - hasOpeningDocument:presenter - Milena",
                                                  "Event1 - hasOpeningDocument:author - João",
                                                  "Event2 - hasClosingDocument:advisor - Schawbe"]},
                  {:key => 1, :pathItems => ["Event", "Person"], :examples => ["Event1 - organizer - Tim Berners Lee"]}
                   ],
            :options => [
                  {:key => 0, :next => currentId + ".0"}, {:key => 1, :next => currentId + ".0"}
                   ]
          }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
    
    choose_relations_of_path_detail(currentId, className, child) #21
  
  end
  
  def choose_relations_of_path_detail(previousId, className, fatherFlowTree) #21
    currentId = previousId.to_s + ".0"
    m = {
            :id => currentId, :title => "Select the relationships", :type => "path", :message => "Suggested path",
            :paths => [
                  {:key => 0, :pathItems => ["Event", "Document", "Person"], :examples => ["Event1 - hasOpeningDocument:presenter - Milena",
                                                  "Event1 - hasOpeningDocument:author - João",
                                                  "Event2 - hasClosingDocument:advisor - Schawbe"]},
                  {:key => 1, :pathItems => ["Event", "Person"], :examples => ["Event1 - organizer - Tim Berners Lee"]}
                 ], 
            :propertySets => [
                      [
                        [
                          {:key => 0, :text => "organizer"}
                          ]
                        ],
                        [
                        [
                          {:key => 0, :text => "hasOpeningDocument"},
                          {:key => 1, :text => "hasClosingDocument"}
                          ],
                          [
                          {:key => 0, :text => "presenter"},
                          {:key => 1, :text => "author"}
                          ]
                        ]
                      ],
            :options => [
                    {:key => 0, :next => currentId + ".0"}, {:key => 1, :next => currentId + ".0"}
                   ]
          }
          
          child = {:value => m, :children => []}
          fatherFlowTree[:children].push(child)
          
          more_attributes_question_detail(currentId, className, child) #18
  
  end
  
  def more_attributes_question_detail(previousId, className, fatherFlowTree) #18
    currentId = previousId.to_s + ".0"
    m = {
            :id => currentId, :title => "", :type => "radioSelectedPropertiesForDetail",
            :message => "Do you want to show more attributes in the Event detail? Which type?",
            :example => "events",
            :options => [
              {:key => 0, :text => "Direct attributes of an Event", :next => previousId[0, previousId.length-6] + ".0"},
              {:key => 1, :text => "Attributes of other classes related to Event", :next => previousId[0, previousId.length-4]},
              {:key => 2, :text => "Computed Attributes", :next => previousId[0, previousId.length-6] + ".2"},
              {:key => 3, :text => "No more", :next => previousId[0, previousId.length-8] + ".1"}
            ]
          }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
end
end