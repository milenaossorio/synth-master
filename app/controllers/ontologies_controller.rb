class OntologiesController < ApplicationController
  # GET /ontologies/wizard/id:/[^\/]+/
  def wizard

    @max_resource_search = 8
    
    @cache = {}

    domain_classes = get_domain_classes_from(params[:url] || 'http://www.semanticweb.org/milena/ontologies/2013/6/auction')
   # domain_classes += get_domain_classes_from('http://data.semanticweb.org/ns/swc/ontology#')
   # domain_classes += get_domain_classes_from('http://xmlns.com/wordnet/1.6/')
      
    #@namespaces = ActiveRDF::Namespace.all
    #result = @namespaces.keys.map{|key| "#{key} - #{@namespaces[key]}"}
    
    wizard = []
    #flowTree = class_step("0.0.0", domain_classes, "swrc")

    #breadthFirstSearch(flowTree, wizard)

    domain_classes.each{ |klass|
    # wizard.push(:klass => klass, :value => get_datatype_properties(klass))
    # wizard.push({:klass => klass, :value => get_examples_for(klass, 3, 'rdfs:label', 'foaf:name', 'foaf:family_name', 'foaf:firstName', 'foaf:mbox_sha1sum')})
    #wizard.push(get_examples_for('Proceedings', 3, 'rdf:label', 'rdf:type', 'owl:sameAs', 'related to Event'))
    # temp = get_related_collections(klass, 1)
    
    # wizard.push({:klass => klass, :value => get_related_collections(klass[:className], 3)})
     #wizard.push({:klass => klass, :value => get_related_collections_getting_properties_domain_range_Aux(klass)})
     
     wizard.push(:klass => klass[:className], :value => get_relations(klass[:className], 2))
    }

    #wizard = get_datatype_properties('Proceedings')
    
    #wizard = get_related_collections('Proceedings', 1, 1)
    
    #wizard = {:value => generate_property_domain_range_from_definition}
     # wizard = domain_classes
    #wizard = result
    
    render :json => {:windows=> wizard}

    # render :json => {:windows=>wizard.select { |e| e[:value].length > 0 }}
  end
  
  def get_examples_using_label_for(className, cant)

    className = RDFS::Class.find_all().select{|x| ActiveRDF::Namespace.localname(x.uri) == className}.first
    resources = className.nil? ? [] : ActiveRDF::ObjectManager.construct_class(className).find_all

    result = resources[0, @max_resource_search].map{|resource|
    resource.rdfs::label.empty? ? "compacturi: #{resource.compact_uri}" : "label: #{resource.rdfs::label.first}"
    }.uniq.compact[0, cant]

    (result.length...cant).each do result.push('No more example') end

    return result
  #return ['Posters Display', 'Demo: Adapting a Map Query Interface...', 'Demo: Blognoon: Exploring a Topic in...']
  end

  def get_examples_for(className, cant, *props)

    className = RDFS::Class.find_all().select{|x| ActiveRDF::Namespace.localname(x.uri) == className}.first
    resources = className.nil? ? [] : ActiveRDF::ObjectManager.construct_class(className).find_all

    result = []
    resources[0, @max_resource_search].each{|res|
      hash = {}
      res.direct_properties.select{|y| !(y.first.is_a?(RDFS::Resource))}.select{|x| props.include?(x.label.first || x.compact_uri)}.each{|property| hash[(property.label.first || property.compact_uri).to_sym] = property.to_s }
      props.each{|prop| unless hash.include?(prop) then hash[prop] = 'No value' end}
      result.push(hash)
    }.uniq.compact[0, cant]

    (result.length...cant).each do
      result.push(Hash[props.map{|prop| [prop, 'No more example']}])
    end

    return result

  #return ['Posters Display', 'Demo: Adapting a Map Query Interface...', 'Demo: Blognoon: Exploring a Topic in...']
  end

  def get_datatype_properties(className)

    _class = RDFS::Class.find_all().select{|x| ActiveRDF::Namespace.localname(x.uri) == className}.first
    resources = ActiveRDF::ObjectManager.construct_class(_class).find_all[0, @max_resource_search]
    result = []
    
    resources.each{|x| 
      result += x.direct_properties.select{|y| !(y.first.is_a?(RDFS::Resource))}.collect{|property| (property.label.first || property.compact_uri)}
    }
    result = result.uniq
    result = ["The '#{className}' has no datatype property"] if result.empty?
    return result

=begin
  if (isFirstSet)
    return ["label", "start", "end", "summary"]
  else
    return ["label", "summary", "Documents"]
  end
=end
  end

  def get_related_collectionsOld(className, level)
   # prop = "rdfs:label"
    _class = RDFS::Class.find_all().select{|x| ActiveRDF::Namespace.localname(x.uri) == className}.first
    resource = ActiveRDF::ObjectManager.construct_class(_class).find_all.first
    
    unless resource.nil? then
      props = resource.direct_properties.select{|y| y.first.is_a?(RDFS::Resource)}
      
     resources = props.collect { |prop| 
               
        temp = (prop.compact_uri =~ /([a-zA-Z0-9]):[a-zA-Z0-9]/) ?
        resource.send(prop.compact_uri.split(":").first).send(prop.compact_uri.split(":").last) :
         resource.send(prop.compact_uri.split("#").last)
         
        [:temp => temp, :resorce_new => RDFS::Resource.new(prop.uri),
           :name => prop.compact_uri, :label => prop.label, :type => prop.type, :prop => prop, 
           :mauricioClasses => prop.first.classes, :mauricioTypes => prop.first.types]
        
    }
    
    #return ["Article", "Book", "Conference", "Event", "Person", "Document"]
    end
  end
  
  def get_related_collections(className, level)

    result = []
    if(level == 0)then return result end 
    
    result = get_direct_collections(className)

    temp = result.collect{|_class|
      get_related_collections(_class, level-1)
    }
    result += temp
    result.flatten.uniq
  end
  
  
  def get_direct_collections(className)
    
    if @cache.has_key?(className) then return @cache[className] end
    
    _class = RDFS::Class.find_all().select{|x| ActiveRDF::Namespace.localname(x.uri) == className}.first
    resource = ActiveRDF::ObjectManager.construct_class(_class).find_all.first
    
    unless resource.nil? then
      collections = resource.direct_properties.select{|y| y.first.is_a?(RDFS::Resource)}[0,5].collect{|r|
         arr = r.first.classes
         arr.shift
         arr}.flatten
      collections = collections.map{|c| c.localname}.uniq
      collections.shift
      @cache[className] = collections
    else
      @cache[className] = []
    end     
    #return ["Article", "Book", "Conference", "Event", "Person", "Document"]
  end
  
   def get_related_collections_getting_properties_domain_range_Aux(className)
    _class = RDFS::Class.select{|x| ActiveRDF::Namespace.localname(x.uri) == className}.first
    resource = ActiveRDF::ObjectManager.construct_class(_class).find_all.first

    unless resource.nil? then
      resource.direct_properties[0,5].select{|y| y.first.is_a?(RDFS::Resource)}.each{|r|
        arr = r.first.classes
        arr.shift
        collections += arr
        @relations.push(r) #it may not be needed
        @props_declaration.push({:propertyName => r.label || r.compact_uri, :domain => resource.first.classes.map{|c| c.localname}.uniq,
          :range => r.first.classes.map{|c| c.localname}.uniq })
        }
        @props_declaration.shift
        @relations.shift
        group_domain_and_range_by_property_name(@props_declaration)
      collections = collections.map{|c| c.localname}.uniq
    collections.shift
    collections
    else
    []
    end
  #return ["Article", "Book", "Conference", "Event", "Person", "Document"]
  end
  
  def generate_triples_examples
    examples[:definition] = generate_property_domain_range_from_definition
    examples[:definition] += generate_property_domain_range_from_instances
  end
  
  def generate_property_domain_range_from_definition(className, level)
    relations = get_relations(className, level).select{|rel| {:propertyName => rel.label || r.compact_uri, :domain => rel.rdfs::domain,
        :range => rel.rdfs::range} if !rel.rdfs::domain.empty? || !rel.rdfs::domain.empty?}
    # relations = [{:propertyName => "name1", :domain => "domain1", :range => "range1"}, #Example to prove grouping domain and range by property name
                 # {:propertyName => "name2", :domain => "domain1", :range => "range2"},
                 # {:propertyName => "name1", :domain => "domain1", :range => "range1"},
                 # {:propertyName => "name1", :domain => "domain3", :range => "range3"}]
    
    #group_domain_and_range_by_property_name(relations)
  end
  
  def group_domain_and_range_by_property_name(relations)
    relations.group_by{|rel| rel[:propertyName]}.values.map{|value| {:propertyName => value.first[:propertyName], #grouping domain and range by property name
      :domain => value.collect{|y| y[:domain]}.uniq, :range => value.collect{|y| y[:range]}.uniq}}
  end
  
  def generate_property_domain_range_from_instances(className, level)
    
  end 
  
  def get_relations(className, level)
    result = []
    if(level == 0)then return result end 
    result = get_relations_aux(className)
    classes = get_direct_collections(className)

    temp = classes.collect{|klass|
      get_relations(klass, level-1)
    }
    
    result += temp
    result.flatten.uniq
  end
  
  def get_relations_aux(className)
    _class = RDFS::Class.find_all().select{|x| ActiveRDF::Namespace.localname(x.uri) == className}.first
    resource = ActiveRDF::ObjectManager.construct_class(_class).find_all.first
    
    puts _class
    puts resource
    puts "---"
    
    relations = []
    
    unless resource.nil? then
      relations = resource.direct_properties.select{|y| y.first.is_a?(RDFS::Resource)}
      #relations.shift
    end     
    
    relations
    
   #_props.map{|prop| prop
     # [:propName => prop.rdfs::label, :domain => prop.rdfs::domain]
      
       # [:resorce_new => RDFS::Resource.new(prop.uri),
           # :name => prop.compact_uri, :label => prop.label, :domain => prop.domain, :type => prop.type, :prop => prop, 
           # :mauricioClasses => prop.classes, :mauricioTypes => prop.types]
           
      # prop.direct_properties#.select{|y| y.first.is_a?(RDFS::Resource)}
    # }     
    
    # ActiveRDF::Query.new.distinct(:s).where(:s,RDF::type,RDF::Property).regexp(:s, (/#{text}/)).execute
#     
    # new_query.distinct(:p).where(:p,RDFS::domain,:t).where(self,RDF::type,:t).execute |
      # new_query.distinct(:p).where(:p,RDFS::domain,:x).where(self.class, RDFS::subClassOf, :x).execute | #Adding RDFS Extensional Entailment Rule (ext1)
      # new_query.distinct(:p).where(:p,RDFS::domain,RDFS::Resource).execute  # all resources share RDFS::Resource properties

  end
  
  # def domain_properties(options={})
    # excluded_namespaces = [:xsd, :rdf, :rdfs, :owl, :shdm, :swui, :symph, :void]
    # RDF::Property.find_all(options).reject{ |c| excluded_namespaces.include?(ActiveRDF::Namespace.prefix(c))  }.map{|value| 
      # ActiveRDF::Namespace.localname(value.uri) if value.uri.index(@param) == 0}.compact
  # end
  
  def get_domain_classes_from(ontology)
    param = ontology
    domain_classes = RDFS::Class.domain_classes.map{|value| 
     {:prefix => ActiveRDF::Namespace.prefix(value), 
      :className => ActiveRDF::Namespace.localname(value)} if value.uri.index(param) == 0}.compact
  end

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
      example_list(currentId, name, get_examples_for(name, 3, 'rdf:label'), child)
      example_detail(currentId, name, get_datatype_properties(name), child)

    }

  end

  

  
  def new_query
    
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
    examples = get_examples_for(className, 3, 'rdf:label');
    example_list_choose_one_more_attributes_question(currentId, className, examples, child)
    example_list_choose_more_than_one_more_attributes_question(currentId, className, examples, child)

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
      :messageOptions => "Do you want to show other attributes of a(n) #{className} than those shown in the example?",
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
        {:key => 0, :text => "Direct attributes of a(n) #{className}", :next => currentId + ".0"},
        {:key => 1, :text => "Attributes of other classes related to #{className}", :next => currentId + ".1"},
        {:key => 2, :text => "Computed Attributes", :next => currentId + ".2"}
      ]
    }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)

    datatype_properties_selection_detail(currentId, className, get_datatype_properties(className), child)
    related_collection_detail(currentId, className, get_related_collections(className), child)
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

    datatype_properties_selection_list(currentId, className, get_datatype_properties(className), child)
    related_collection_list(currentId, className, get_related_collections(className), child)
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
            "Event2 - hasClosingDocument:advisor - Schwabe"]},
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