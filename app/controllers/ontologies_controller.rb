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
    class_step("1.1.1", wizard, domain_classes, "swrc");
    class_next_step("1.1.1.1", wizard, domain_classes);
    render :json => {:windows=>wizard}
  end
  
  def class_step(previousId, wizard, classes, prefix)
    index = -1
    currentId = previousId + ".1"
    m = {:id => currentId, :type => 'select', :title => "What do you want to show from #{prefix} ontology?", 
      :message => 'Class', :options => []}
    m[:options] = classes.map{|className| {:key=>(index += 1), :text=>className, :next=>currentId + "." + index.to_s}}
    wizard.push(m);
  end
  
  def class_next_step(previousId, wizard, classes)
    index = -1
    
    classes.each{ |name|
      currentId = (previousId + "." + (index += 1).to_s)
      m = {:id => currentId, :type => 'radio', :title => 'What do you want to do?', 
        :message => '',
        :options => [
          {:key => 0, :text => "Show a list of #{name} to be chosen", :next => currentId + ".0"},
          {:key => 1, :text => "Show the detail of a(n) #{name}", :next => currentId + ".1"},
          {:key => 2, :text => "Define a computation using a(n) #{name}", :next => currentId + ".2"}
          ]}
      wizard.push(m);
    }
  end

end