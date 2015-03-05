class OntologiesController < ApplicationController
  # GET /ontologies/wizard/id:/[^\/]+/
  def init
    @max_resource_search = 12
    @max_number_examples = 5
    
    @cache = {}
    @cache_domain_range = {}
    @cache_collections = {}
    @cache_triples = {}
    @relations = []
    @props_declaration = []

  end

  def wizard
    
    init()
    
    domain_classes = get_domain_classes_from(params[:url] || 'http://www.semanticweb.org/milena/ontologies/2013/6/auction')
   # domain_classes += get_domain_classes_from('http://data.semanticweb.org/ns/swc/ontology#')
   # domain_classes += get_domain_classes_from('http://xmlns.com/wordnet/1.6/')
      
    #@namespaces = ActiveRDF::Namespace.all
    #result = @namespaces.keys.map{|key| "#{key} - #{@namespaces[key]}"}
    
    wizard = []
    flowTree = class_step("0.0.0", domain_classes, "auction")
    
    breadthFirstSearch(flowTree, wizard)
    
    

    # wizard.push(:klass => 'Produto', :value => generate_property_domain_range_from_definition('Produto', 2))
    # wizard.push(:klass => 'Produto', :value => {:collections => get_direct_collections_getting_properties_domain_range('Produto')}), 
      # :relations => @relations, :props_declaration => @props_declaration})

      # domain_classes.each{ |klass| 
      # wizard.push(:klass => klass[:className], :value => get_related_collectionsOld(klass[:className], 2))
     # }
    
    # wizard.push(:klass => klass[:className], :value => get_datatype_properties(klass[:className]))
#     
    # wizard.push({:klass => klass[:className], :value => get_examples_for(klass[:className], 3, *get_datatype_properties(klass[:className]))})
#     
    # } 
    # wizard.push({:klass => klass, :value => get_examples_for(klass, 3, 'rdfs:label', 'foaf:name', 'foaf:family_name', 'foaf:firstName', 'foaf:mbox_sha1sum')})
    #wizard.push(get_examples_for('Proceedings', 3, 'rdf:label', 'rdf:type', 'owl:sameAs', 'related to Event'))
    # temp = get_related_collections(klass, 1)
    
    # wizard.push({:klass => klass, :value => get_related_collections(klass[:className], 3)})
     #wizard.push({:klass => klass, :value => get_related_collections_getting_properties_domain_range_Aux(klass)})

    
    #wizard.push(:klass => 'Produto', :value => generate_triples_examples('Leilao', 4))
    #path = [{:propertiesNames => ["temProduto"], :className => "Produto"},
     #       {:propertiesNames => ["categoria"], :className => "Categoria"}]
    #wizard.push(:klass => 'Produto', :value => get_objects_from("leilao1", "temProduto", generate_triples_examples('Leilao', 4)[:triples]))
    #wizard.push(:klass => 'Leilao', :value => get_path_examples("Leilao", path))
    
    #wizard.push(:klass => 'Produto', :value => get_properties_domain_range_from_instances('Produto', 4))
    #wizard = get_datatype_properties('Proceedings')
    
    #wizard = get_related_collections('Proceedings', 1, 1)
    
    #wizard = {:value => generate_property_domain_range_from_definition}
     # wizard = domain_classes
    #wizard = result
    #a = get_datatype_properties('Produto')
    render :json => {:windows=> wizard, :data => get_data_of_wizard}

    # render :json => {:windows=>wizard.select { |e| e[:value].length > 0 }}
  end
  
  def get_data_of_wizard
    domain_classes = get_domain_classes_from(params[:url] || 'http://www.semanticweb.org/milena/ontologies/2013/6/auction')
    data_hash = {}
    domain_classes.each{|_class|
       props = get_datatype_properties(_class[:className])
       examples = get_examples_for(_class[:className], 3, *props)
       arr = examples.collect{|ex_hash| 
         ex_hash.sort.each_with_index.collect{|(key, value), index|
            {:id => index, :name => key, :value => [value]}
         }
      }
      data_hash[_class[:className]] = arr      
    }
    data_hash
  end
  
  def examples
    
    init()
    
    domain_classes = get_domain_classes_from(params[:url] || 'http://www.semanticweb.org/milena/ontologies/2013/6/auction')
    examples = {:definition => [], :triples => []}
    domain_classes.each{|_class|
      temp = generate_triples_examples(_class[:className], @max_number_examples)
      examples[:definition].push(temp[:definition]);
      examples[:triples].push(temp[:triples]);
    }
    
    examples[:definition] = group_domain_and_range_by_property_name(examples[:definition].flatten)
    examples[:triples] = examples[:triples].flatten.uniq

    render :json => examples;
    
  end
  
  def get_path_examples(initialClass, path) #it is not used. It is in app.js
    examples = generate_triples_examples(initialClass)
    initialInstances = get_instances_of_class(initialClass, examples[:triples])
    initialInstances.collect{|initInst|
      rest_examples = get_rest_of_path_examples(initInst, path, 0, examples[:triples])
      rest_examples.collect{|rest_ex|
        initInst + " - " +  rest_ex       
      }
    }
  end
  
   def get_rest_of_path_examples(subject, path, pos, triples) #it is not used. It is in app.js

    result = []
    path[pos][:propertiesNames].each{|prop|
      objects = get_objects_from(subject, prop, triples)
      if pos == path.length - 1 then
        insts = get_instances_of_class(path[path.length - 1][:className], triples)
        objects.select{|obj| insts.include?(obj)}.each{|obj|
          result.push(prop + " - " + obj)
        }
      else
        objects.each{|obj|
          rest_examples = get_rest_of_path_examples(obj, path, pos + 1, triples)
          rest_examples.each{|rest_ex|
            temp = prop + ":" + rest_ex
            if temp.split(':').length == path.length - pos then
              result.push(temp)
            end
          }
        }
      end
    }
    result
  end
  
  def get_instances_of_class(className, triples) #it is not used. It is in app.js   
    triples.select{|triple| triple[:predicate] == "type" && triple[:object] == className}.collect{|triple| triple[:subject]}
  end
  
  def get_objects_from(subject, prop, triples) #it is not used. It is in app.js
   triples.select{|triple| triple[:subject] == subject && triple[:predicate] == prop}.collect{|triple| triple[:object]}
  end
  
  def get_domain_classes_from(ontology)
    param = ontology
    domain_classes = RDFS::Class.domain_classes.map{|value| 
     {:prefix => ActiveRDF::Namespace.prefix(value), 
      :className => ActiveRDF::Namespace.localname(value)} if value.uri.index(param) == 0}.compact
  end
  
  def get_examples_using_label_for(className, cant) # it is not used

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
    resources = className.nil? ? [] : ActiveRDF::ObjectManager.construct_class(className).find_all[0, @max_resource_search]
    
     result = []
    resources.each{|res|
      hash = {}
      res.direct_properties.select{|y| !(y.first.is_a?(RDFS::Resource))}.select{|x| props.include?(x.label.first || x.localname || x.compact_uri)}.
      each{|property| hash[(property.label.first || property.localname || property.compact_uri) ] = property.to_s } #(property.label.first || property.compact_uri).to_sym
      props.each{|prop| unless hash.include?(prop) then hash[prop] = 'No value' end}
      result.push(hash)
    }.uniq.compact

    (result.length...cant).each do
      result.push(Hash[props.map{|prop| [prop, 'No more example']}])
    end

    return result[0, cant]

  #return ['Posters Display', 'Demo: Adapting a Map Query Interface...', 'Demo: Blognoon: Exploring a Topic in...']
  end

  def get_datatype_properties(className)
    result = []
    _class = RDFS::Class.find_all().select{|x| ActiveRDF::Namespace.localname(x.uri) == className}.first
    
    puts "----------------------'#{className}' ----------------------------------------" if _class.nil?
    
    resources = ActiveRDF::ObjectManager.construct_class(_class).find_all[0, @max_resource_search]

    resources.each{|x| 
      result += x.direct_properties.select{|y| !(y.first.is_a?(RDFS::Resource))}.
                collect{|property| (property.label.first || property.localname  || property.compact_uri )}
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

  def get_related_collectionsOld(className, level) # it is not used
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
  
  def get_related_collections(className)
     collections = get_related_collections_from(className)
     domain_classes = get_domain_classes_from(params[:url] || 'http://www.semanticweb.org/milena/ontologies/2013/6/auction')
     domain_classes.each{|_class|
       arr = get_related_collections_from(_class[:className])
       if(arr.include?(className)) then
         collections.push(_class[:className])
       end
     }
     
     collections
  end
  
  
  def get_related_collections_from(className, level = 3)

    result = []
    if(level == 0)then return result end 
    
    result = get_direct_collections(className)

    temp = result.collect{|_class|
      get_related_collections_from(_class, level-1)
    }
    result += temp
    result.flatten.uniq
  end
  
  
  def get_direct_collections(className)
    
    if @cache_collections.has_key?(className) then return @cache_collections[className] end
    
    _class = RDFS::Class.find_all().select{|x| ActiveRDF::Namespace.localname(x.uri) == className}.first
    resource = ActiveRDF::ObjectManager.construct_class(_class).find_all.first
    
    unless resource.nil? then
      collections = resource.direct_properties.select{|y| y.first.is_a?(RDFS::Resource)}.collect{|r|
         arr = r.first.classes
         arr.shift
         arr}.flatten
      # collections += resource.reversed_direct_properties.select{|y| y.first.is_a?(RDFS::Resource)}.collect{|r|
         # arr = r.first.classes
         # arr.shift
         # arr}.flatten   
         
           
      collections = collections.map{|c| c.localname}.reject{|x| x == "NamedIndividual"}.uniq
      collections.shift
      @cache_collections[className] = collections
    else
      @cache_collections[className] = []
    end     
    #return ["Article", "Book", "Conference", "Event", "Person", "Document"]
  end
  
  def get_direct_collections_getting_properties_domain_range(className) # it is not used
     
    if @cache.has_key?(className) then return @cache[className] end
     
    _class = RDFS::Class.find_all().select{|x| ActiveRDF::Namespace.localname(x.uri) == className}.first
    resource = ActiveRDF::ObjectManager.construct_class(_class).find_all.first
    
    collections=[]

    unless resource.nil? then
      resource.direct_properties.select{|y| y.first.is_a?(RDFS::Resource)}.each{|r|
        arr = r.first.classes
        arr.shift
        collections += arr
        @relations.push(r) #it may not be needed
        # @props_declaration.push({:propertyName => r.label || r.compact_uri, :domain => resource.first.classes.map{|c| c.localname}.uniq,
          # :range => r.first.classes.map{|c| c.localname}.uniq })
        }
       # @props_declaration.shift
       # @relations.shift
        # group_domain_and_range_by_property_name(@props_declaration)
      collections = collections.map{|c| c.localname}.uniq
    #collections.shift
    collections
    @cache[className] = collections
    else
      @cache[className] = []
    end
  #return ["Article", "Book", "Conference", "Event", "Person", "Document"]
  end
  
  def generate_triples_examples(className, level = 3)
    examples = {}
    examples[:definition] = get_property_domain_range_from_definition(className, level)
    examples[:definition] += get_properties_domain_range_from_instances(className, level)
    examples[:definition] = group_domain_and_range_by_property_name(examples[:definition])
    examples[:triples] = get_instances_triples(className, level)
    examples
  end
  
  def hasValue (collection)
    filter = ['Resource', 'NamedIndividual']
    collection.each{|c|
      return true if filter.include?(ActiveRDF::Namespace.localname(c))
    }
    return false
  end
  
  def get_property_domain_range_from_definition(className, level)
    relations = get_relations(className, level).select{
      |rel| !hasValue(rel.rdfs::domain) && !hasValue(rel.rdfs::range)
    }.map{|rel| 
      {:propertyName => ActiveRDF::Namespace.localname(rel.uri),
         :domain => rel.rdfs::domain.map{|d| ActiveRDF::Namespace.localname(d)}, 
         :range => rel.rdfs::range.map{|r| ActiveRDF::Namespace.localname(r)}
      }
    }
    
    # relations = [{:propertyName => "name1", :domain => "domain1", :range => "range1"}, #Example to prove grouping domain and range by property name
                 # {:propertyName => "name2", :domain => "domain1", :range => "range2"},
                 # {:propertyName => "name1", :domain => "domain1", :range => "range1"},
                 # {:propertyName => "name1", :domain => "domain3", :range => "range3"}]
    
    group_domain_and_range_by_property_name(relations)
  end
  
  def group_domain_and_range_by_property_name(relations)
    relations.group_by{|rel| rel[:propertyName]}.values.map{|value| {:propertyName => value.first[:propertyName], #grouping domain and range by property name
      :domain => value.collect{|y| y[:domain]}.flatten.uniq, :range => value.collect{|y| y[:range]}.flatten.uniq}}
  end
  
  def get_properties_domain_range_from_instances(className, level)

    result = []
    if(level == 0)then return result end 
      
    result = get_direct_properties_domain_range_from_instances(className)       
    
    classes = get_direct_collections(className)

    temp = classes.collect{|_class|
      get_properties_domain_range_from_instances(_class, level-1)
    }
    result += temp
    result.flatten.uniq
  end
  
  def get_direct_properties_domain_range_from_instances(className)
    
    if @cache_domain_range.has_key?(className) then return @cache_domain_range[className] end
      
    
    _class = RDFS::Class.find_all().select{|x| ActiveRDF::Namespace.localname(x.uri) == className}.first
    resource = ActiveRDF::ObjectManager.construct_class(_class).find_all.first 
    
    unless resource.nil? then
      triples = resource.direct_properties.select{
        |prop| !hasValue(resource.classes) && !hasValue((prop.first.is_a?(RDFS::Resource)? prop.first.classes : prop.rdfs::range))
      }.collect{|prop|
         {:propertyName => prop.localname,
         :domain => resource.classes.map{|d| d.localname}, 
         :range => (prop.first.is_a?(RDFS::Resource)? prop.first.classes : prop.rdfs::range).map{|r| r.localname}
         }
      }   
      @cache_domain_range[className] = triples
    else
      @cache_domain_range[className] = []
    end     
    #return ["Article", "Book", "Conference", "Event", "Person", "Document"]
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
    
    relations = []
    
    unless resource.nil? then
      relations = resource.direct_predicates
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
  
  def get_instances_triples(className, level)
      
    _class = RDFS::Class.find_all().select{|x| ActiveRDF::Namespace.localname(x.uri) == className}.first
    resources = ActiveRDF::ObjectManager.construct_class(_class).find_all[0, @max_number_examples]
    
    #get_direct_instances_triples_including_datatype_properties(resources)
    
    get_instances_triples_Aux(resources, level)    
   
  end
  
  def get_instances_triples_Aux(resources, level)
    resp = []
    if level == 0 then return resp end
    unless resources.nil? then    
      resources.each{|resource|
        unless resource.nil?
          result = get_direct_instances_triples_including_datatype_properties(resource)
          resp += result[:triples]
          resp += get_instances_triples_Aux(result[:direct_instances], level-1)
        end
      }
    end
    
    resp.uniq
  end
  
  
  def get_direct_instances_triples(resource)# get only triples of object properties # it is not used in the meanwhile
 
    if @cache_triples.has_key?(resource) then return @cache_triples[resource] end
      
    direct_instances = []
    triples = []        
        
    resource.direct_properties.select{|y| y.first.is_a?(RDFS::Resource)}.each{|prop|
     direct_instances += prop
     triples.push({:subject => resource.localname, :predicate => prop.localname, :object => prop.first.localname})
    }   
       
    @cache_triples[resource] = {:direct_instances => direct_instances, :triples => triples} 
    
  end
  
   def get_direct_instances_triples_including_datatype_properties(resource) #it is like get_direct_instances_triples but including datatype properties

    if !resource.is_a?(RDFS::Resource) then return {:direct_instances => [], :triples => []} end

    if @cache_triples.has_key?(resource) then return @cache_triples[resource] end

    direct_instances = []
    triples = []

    resource.direct_properties.each{|prop|
      direct_instances.push(prop)
      prop.each{|p|
        triples.push({:subject => resource.localname,
          :predicate => prop.localname,
          :object => p.respond_to?("localname")? p.localname : p})

      }
    }

    @cache_triples[resource] = {:direct_instances => direct_instances.flatten.uniq, :triples => triples}
  
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
    m[:options] = classes.map{|klass| {:key=>(index += 1), :text=>klass[:className], :next=>currentId + "." + index.to_s}}
    flowTree = {:value => m, :children => []}

    class_next_step(currentId, classes, flowTree);
    return flowTree
  #wizard.push(m);
  end

  def class_next_step(previousId, classes, fatherFlowTree) #5, 28, ...
    index = -1
    aux = []
    classes.each{ |name|
      name = name[:className]
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
      example_list(currentId, name, get_examples_for(name, @max_number_examples, 'label'), child)
      example_detail(currentId, name, get_datatype_properties(name), child)

    }

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
          [{:type => "text", :msg => examples[0].values.first}],
          [{:type => "text", :msg => examples[1].values.first}],
          [{:type => "text", :msg => examples[2].values.first }]
        ],
        [
          [{:type => "img", :msg => '/assets/checkbox-checked.png'},{:type => "text", :msg => examples[0].values.first}],
          [{:type => "img", :msg => '/assets/checkbox.png'},{:type => "text", :msg => examples[1].values.first}],
          [{:type => "img", :msg => '/assets/checkbox-checked.png'},{:type => "text", :msg => examples[2].values.first}]
        ]
      ]
    }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
    examples = get_examples_for(className, 3, 'label');
    example_list_choose_one_more_attributes_question(currentId, className, examples, child)
    example_list_choose_more_than_one_more_attributes_question(currentId, className, examples, child)

  end

  def example_detail(previousId, className, datatypeProperties, fatherFlowTree) # 15, 42, ...
    currentId = previousId.to_s + ".1"
    m = {:id => currentId, :title => "#{className} detail", :type => "yesNoDetail", :scope => "new", :example =>className,
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
      :id => currentId, :title => "", :type => "infoWithOptions", :scope => "new", :example =>className, :message => "#{className}s",
      :messageOptions => "Do you want to show other attributes of an #{className} than those shown in the example?",
      :options => [
        {:key => 0, :text => "Yes", :next => currentId + ".0"},{:key => 1, :text => "No", :next => currentId + ".1"}
      ],
      :details => [
        [{:type => "text", :msg => examples[0].values.first}],
        [{:type => "text", :msg => examples[1].values.first}],
        [{:type => "text", :msg => examples[2].values.first}]
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
      :id => currentId, :title => "", :type => "infoWithOptions", :scope => "new", :example =>className, :message => "#{className}s",
      :messageOptions => "Do you want to show other attributes of a(n) #{className} than those shown in the example?",
      :options => [
        {:key => 0, :text => "Yes", :next => previousId.to_s + ".0.0"},{:key => 1, :text => "No", :next => previousId.to_s + ".0.1"}
      ],
      :details => [
        [{:type => "img", :msg => "/assets/checkbox-checked.png"},{:type => "text", :msg => examples[0].values.first}],
        [{:type => "img", :msg => "/assets/checkbox.png"},{:type => "text", :msg => examples[1].values.first}],
        [{:type => "img", :msg => "/assets/checkbox-checked.png"},{:type => "text", :msg => examples[2].values.first}]
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
        {:key => 0, :text => "Yes", :child => "Yes", :next => currentId + ".0" },
        {:key => 1, :text => "No", :child => "End", :next => currentId + ".1"}
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
        {:key => 0, :text => "Yes", :child => "Yes", :next => currentId + ".0"},
        {:key => 1, :text => "No", :child => "End", :next => previousId[0, previousId.length-4] + ".1.1.1"}
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
      :type => "checkboxForDetail", :scope => "scope", :message => "Add #{className} properties", :example => className,
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
      :mainclass => className,
      :options => relatedCollections.each_with_index.collect{|collection, index|
          {:key => index, :text => collection, :next => currentId + ".0"}
        }
      # [
        # {:key => 0, :text => relatedCollections[0], :next => currentId + ".0"},
        # {:key => 1, :text => relatedCollections[1], :next => currentId + ".0"},
        # {:key => 2, :text => relatedCollections[2], :next => currentId + ".0"},
        # {:key => 3, :text => relatedCollections[3], :next => currentId + ".0"},
        # {:key => 4, :text => relatedCollections[4], :next => currentId + ".0"},
        # {:key => 5, :text => relatedCollections[5], :next => currentId + ".0"}
      # ]
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
        {:key => 0, :text => "Go to the pages index", :next => "0.0.0.0"},
        {:key => 1, :text => "Finish the application definition", :next => "#{currentId}."}
      ]
    }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)

  end

  def datatype_properties_selection_list(previousId, className, datatypeProperties, fatherFlowTree) #9
    currentId = previousId.to_s + ".0"
    m = {
      :id => currentId, :title => "Following this example which attributes you want to show in the #{className} list",
      :type => "checkbox", :scope => "scope", :message => "Add #{className} properties", :example => className,
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
      :id => currentId, :title => "Select what you want to show",
      :type => "select",
      :message => "#{className}'s \t related collections",
      :mainclass => className,
      :options => relatedCollections.each_with_index.collect{|collection, index|
          {:key => index, :text => collection, :next => currentId + ".0"}
        }
      # [
        # {:key => 0, :text => relatedCollections[0], :next => currentId + ".0"},
        # {:key => 1, :text => relatedCollections[1], :next => currentId + ".0"},
        # {:key => 2, :text => relatedCollections[2], :next => currentId + ".0"},
        # {:key => 3, :text => relatedCollections[3], :next => currentId + ".0"},
        # {:key => 4, :text => relatedCollections[4], :next => currentId + ".0"},
        # {:key => 5, :text => relatedCollections[5], :next => currentId + ".0"}
      # ]
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
      :type => "attributeForChoosing", :message => "#{className}s", :example => className,
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
      :id => currentId, :title => "Select the path", :type => "paths", :message => "Suggested paths", :next => currentId + ".0"
    }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)

    choose_relations_of_path(currentId, className, child) #12

  end

  def choose_relations_of_path(previousId, className, fatherFlowTree) #12
    currentId = previousId.to_s + ".0"
    m = {
      :id => currentId, :title => "Select the relationships", :type => "path", :message => "Suggested path", :next => currentId + ".0"
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
      :id => currentId, :title => "Select the path", :type => "paths", :message => "Suggested paths", :next => currentId + ".0"
    }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)

    choose_relations_of_path_detail(currentId, className, child) #21

  end

  def choose_relations_of_path_detail(previousId, className, fatherFlowTree) #21
    currentId = previousId.to_s + ".0"
    m = {
      :id => currentId, :title => "Select the relationships", :type => "path", :message => "Suggested path", :next => currentId + ".0"      
    }

    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)

    more_attributes_question_detail(currentId, className, child) #18

  end

  def more_attributes_question_detail(previousId, className, fatherFlowTree) #18
    currentId = previousId.to_s + ".0"
    m = {
      :id => currentId, :title => "", :type => "radioSelectedPropertiesForDetail",
      :message => "Do you want to show more attributes in the #{className} detail? Which type?",
      :example => className,
      :options => [
        {:key => 0, :text => "Direct attributes of a(n) #{className}", :next => previousId[0, previousId.length-6] + ".0"},
        {:key => 1, :text => "Attributes of other classes related to #{className}", :next => previousId[0, previousId.length-4]},
        {:key => 2, :text => "Computed Attributes", :next => previousId[0, previousId.length-6] + ".2"},
        {:key => 3, :text => "No more", :next => previousId[0, previousId.length-8] + ".1"}
      ]
    }
    child = {:value => m, :children => []}
    fatherFlowTree[:children].push(child)
  end
end