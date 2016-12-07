//
//  {{ profile.targetname }}.swift
//  SwiftFHIR
//
//  Generated from FHIR {{ info.version }} ({{ profile.url }}) on {{ info.date }}.
//  {{ info.year }}, SMART Health IT.
//

import Foundation
{% for klass in classes %}

/**
{{ klass.short|wordwrap(width=120, wrapstring="\n") }}.
{%- if klass.formal %}

{{ klass.formal|wordwrap(width=120, wrapstring="\n") }}
{%- endif %}
*/
open class {{ klass.name }}: {{ klass.superclass.name|default('FHIRAbstractBase') }} {
	{%- if klass.resource_type %}
	override open class var resourceType: String {
		get { return "{{ klass.resource_type }}" }
	}
	{% endif %}
	
	{%- for prop in klass.properties %}
	{%- if prop.enum %}
	/// {{ prop.formal|wordwrap(width=112, wrapstring="\n	/// ") }}
	{%- if prop.enum.restricted_to %}
	/// Only use: {{ prop.enum.restricted_to }}
	{%- endif %}
	{%- else %}
	/// {{ prop.short|wordwrap(width=112, wrapstring="\n	/// ") }}.
	{%- endif %}
	public var {{ prop.name }}: {% if prop.is_array %}[{% endif %}{{ prop.enum.name or prop.class_name }}{% if prop.is_array %}]{% endif %}?
	{% endfor -%}
	
	{% if klass.has_nonoptional %}
	
	/** Convenience initializer, taking all required properties as arguments. */
	public convenience init(
	{%- for nonop in klass.nonexpanded_properties %}{% if nonop.nonoptional %}
		{%- if past_first_item %}, {% endif -%}{% set past_first_item = True -%}
		{%- if nonop.one_of_many -%}
		{{ nonop.one_of_many }}: Any
		{%- else -%}
		{{ nonop.name }}: {% if nonop.is_array %}[{% endif %}{{ nonop.enum.name or nonop.class_name }}{% if nonop.is_array %}]{% endif %}
		{%- endif -%}
	{%- endif %}{% endfor -%}
	) {
		self.init()
	{%- for nonop in klass.nonexpanded_properties %}{% if nonop.nonoptional %}
		{%- if nonop.one_of_many %}{% for expanded in klass.expanded_nonoptionals[nonop.one_of_many] %}
		{% if past_first_item %}else {% endif -%}{% set past_first_item = True -%}
		if let value = {{ nonop.one_of_many }} as? {{ expanded.class_name }} {
			self.{{ expanded.name }} = value
		}
		{%- endfor %}
		else {
			fhir_warn("Type “\(type(of: {{ nonop.one_of_many }}))” for property “\({{ nonop.one_of_many }})” is invalid, ignoring")
		}
		{%- else %}
		self.{{ nonop.name }} = {{ nonop.name }}
		{%- endif %}
	{%- endif %}{% endfor %}
	}
	{% endif -%}
	
	{% if klass.properties %}
	
	override open func populate(from json: FHIRJSON, presentKeys: inout Set<String>) throws -> [FHIRValidationError]? {
		var errors = try super.populate(from: json, presentKeys: &presentKeys) ?? [FHIRValidationError]()
		{% for prop in klass.properties %}
		
		{%- if prop.enum %}{% if prop.is_array %}
		{{ prop.name }} = createEnums(of: {{ prop.enum.name }}.self, for: "{{ prop.orig_name }}", in: json, presentKeys: &presentKeys, errors: &errors)
		{%- else %}
		{{ prop.name }} = createEnum(type: {{ prop.enum.name }}.self, for: "{{ prop.orig_name }}", in: json, presentKeys: &presentKeys, errors: &errors)
		{%- endif %}{% else %}
		
		{%- if prop.is_array %}{% if prop.is_native %}
		// TODO: NATIVE ARRAY of {{ prop.class_name }}: {{ prop.orig_name }}
		presentKeys.insert("{{ prop.orig_name }}")
		{%- else %}
		{{ prop.name }} = try createInstances(of: {{ prop.class_name }}.self, for: "{{ prop.orig_name }}", in: json, presentKeys: &presentKeys, errors: &errors, owner: self)
		{%- endif %}{% else %}{% if prop.is_native %}
		// TODO: NATIVE {{ prop.class_name }}: {{ prop.orig_name }}
		presentKeys.insert("{{ prop.orig_name }}")
		{%- else %}{% if "Resource" == prop.class_name %}     {#- The `Bundle` and a few others have generic resources #}
		if let js = json["{{ prop.orig_name }}"] as? FHIRJSON {
			self.{{ prop.name }} = try Resource.instantiate(from: js, owner: self) as? Resource
		}
		{%- else %}
		{{ prop.name }} = try createInstance(type: {{ prop.class_name }}.self, for: "{{ prop.orig_name }}", in: json, presentKeys: &presentKeys, errors: &errors, owner: self)
		{%- endif %}{% endif %}{% endif %}{% endif %}
		
		{%- if prop.nonoptional and not prop.one_of_many %}
		if nil == {{ prop.name }}{% if prop.is_array %} || {{ prop.name }}!.isEmpty{% endif %} {
			errors.append(FHIRValidationError(missing: "{{ prop.orig_name }}"))
		}
		{%- endif %}
		{%- endfor %}
		
		{%- if klass.expanded_nonoptionals %}
		
		// check if nonoptional expanded properties (i.e. at least one "answer" for "answer[x]") are present
		{%- for exp, props in klass.sorted_nonoptionals %}
		if {% for prop in props %}nil == self.{{ prop.name }}{% if not loop.last %} && {% endif %}{% endfor %} {
			errors.append(FHIRValidationError(missing: "{{ exp }}[x]"))
		}
		{%- endfor %}
		{% endif %}
		return errors.isEmpty ? nil : errors
	}
	
	override open func asJSON(errors: inout [FHIRValidationError]) -> FHIRJSON {
		var json = super.asJSON(errors: &errors)
		{% for prop in klass.properties %}
		if let {{ prop.name }} = self.{{ prop.name }} {
		
		{%- if prop.is_array %}{% if prop.enum %}
			json["{{ prop.orig_name }}"] = {{ prop.name }}.map() { $0.rawValue }
		{%- else %}
			json["{{ prop.orig_name }}"] = {{ prop.name }}.map() { $0.asJSON(errors: &errors) }
		{%- endif %}
		
		{%- else %}{% if prop.enum %}
			json["{{ prop.orig_name }}"] = {{ prop.name }}.rawValue
		{%- else %}
			json["{{ prop.orig_name }}"] = {{ prop.name }}.asJSON(errors: &errors)
		{%- endif %}{% endif %}
		}
		{%- if prop.nonoptional and not prop.one_of_many %}
		else {
			errors.append(FHIRValidationError(missing: "{{ prop.name }}"))
		}
		{%- endif %}
		{%- endfor %}
		{%- if klass.expanded_nonoptionals %}
		
		// check if nonoptional expanded properties (i.e. at least one "value" for "value[x]") are present
		{%- for exp, props in klass.sorted_nonoptionals %}
		if {% for prop in props %}nil == self.{{ prop.name }}{% if not loop.last %} && {% endif %}{% endfor %} {
			errors.append(FHIRValidationError(missing: "{{ exp }}[x]"))
		}
		{%- endfor %}{% endif %}
		
		return json
	}
{%- endif %}
}
{% endfor %}

