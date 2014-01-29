<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');
/**
 * Game AdminPanel (АдминПанель)
 *
 * @package		Game AdminPanel
 * @author		Nikita Kuznetsov (ET-NiK)
 * @copyright	Copyright (c) 2014, Nikita Kuznetsov (http://hldm.org)
 * @license		http://www.gameap.ru/license.html
 * @link		http://www.gameap.ru
 * @filesource	
 */
 
// ------------------------------------------------------------------------

/**
 * Бан подсетей на GolSource серверах
 * 
 * Для полноценной работы на игровых серверах требуется плагин
 * Subnetban (бан подсетей) http://aghl.ru/forum/viewtopic.php?f=19&t=282
 *
 * @package		Game AdminPanel
 * @category	Controllers
 * @author		Nikita Kuznetsov (ET-NiK)
 * @sinse		0.8.10
 */
class Subnetban extends MX_Controller {
	
	//Template
	var $tpl_data = array();
	
	// ------------------------------------------------------------------------
	
	public function __construct()
    {
        parent::__construct();
		
		$this->load->database();
        $this->load->model('users');
        
        if ($this->users->check_user()) {
			
			/* Без админских прав сегодня никуда */
			if(!$this->users->auth_data['is_admin']) {
				redirect('admin');
			}
			
			//Base Template
			$this->tpl_data['title'] 	= 'SubnetBan';
			$this->tpl_data['heading'] 	= 'SubnetBan';
			$this->tpl_data['content'] = '';
			$this->tpl_data['menu'] = $this->parser->parse('menu.html', $this->tpl_data, true);
			$this->tpl_data['profile'] = $this->parser->parse('profile.html', $this->users->tpl_userdata(), true);
			
			$this->load->model('servers');
			$this->load->model('sbdb');
			
        } else {
            redirect('auth');
        }
    }
    
    // ------------------------------------------------------------------------
    
    /**
     * Проверяет SB базу. Вернет ошибку, иначе false.
    */
    private function _found_db_errors($sbdb_cfg, $edit_db = false) 
    {
		if (!$sbdb_new = $this->load->database($sbdb_cfg, true)) {
			return 'Не удалось соединиться с базой данных';
		}
		
		// Проверяем бд, возможно такая база уже есть
		if (!$edit_db) {
			
			$sbdb_cfg['dbprefix'] = isset($sbdb_cfg['dbprefix']) ? $sbdb_cfg['dbprefix'] : '';
			
			$where = array('hostname' => $sbdb_cfg['hostname'], 'database' => $sbdb_cfg['database'], 'dbprefix' => $sbdb_cfg['dbprefix']);
			$this->db->where($where);
			$query = $this->db->get('sb_databases');
			
			if ($query->num_rows > 0) {
				return 'Такая база уже имеется';
			}
		}
		
		/* Существует ли таблица */
		if (!$sbdb_new->table_exists($sbdb_cfg['table_name'])) {
			return 'В базе данных отсутствует таблица ' . $sbdb_cfg['table_name'];
		}
		
		/* Проверка полей таблицы*/
		$fields = $sbdb_new->list_fields($sbdb_cfg['table_name']);
		
		if (!in_array('startip', $fields)) {
			return 'В базе данных отсутствует поле startip';
		}
		
		if (!in_array('endip', $fields)) {
			return 'В базе данных отсутствует поле endip';
		}
		
		if (!in_array('allowedclients', $fields)) {
			return 'В базе данных отсутствует поле allowedclients';
		}
		
		if (!in_array('datetimebanned', $fields)) {
			return 'В базе данных отсутствует поле datetimebanned';
		}
		
		if (!in_array('datetimelastblocked', $fields)) {
			$this->_show_message('В базе данных отсутствует поле datetimelastblocked');
			return false;
		}
		
		if (!in_array('reason', $fields)) {
			return 'В базе данных отсутствует поле reason';
		}
		
		return false;
	}
    
    // ------------------------------------------------------------------------
    
    /**
     * Получение списка subnetban баз и обработка их для вставки в шаблон
    */
    private function _tpl_db_list()
    {
		$sb_db_list = $this->sbdb->get_db_list();
		
		if (empty($sb_db_list)) {
			return array();
		}
		
		foreach ($sb_db_list as &$db) {
			unset($db['username']);
			unset($db['password']);
			unset($db['database']);
			unset($db['dbprefix']);
			
			$db['db_id'] = $db['id'];
			$db['sbdb_id'] = $db['id'];
		}
		
		return $sb_db_list;
	}
	
	// ------------------------------------------------------------------------
    
    /**
     * Преобразует cidr в range ip
     * http://stackoverflow.com/questions/4931721/getting-list-ips-from-cidr-notation-in-php
    */
	private function _cidr2range($cidr) 
	{
		$range = array();
		$cidr = explode('/', $cidr);
		
		if (!filter_var($cidr[0], FILTER_VALIDATE_IP)) {
			return false;
		}
		
		if (!isset($cidr[1])) {
			return false;
		}
		
		$range[0] = long2ip((ip2long($cidr[0])) & ((-1 << (32 - (int)$cidr[1]))));
		$range[1] = long2ip((ip2long($cidr[0])) + pow(2, (32 - (int)$cidr[1])) - 1);
		return $range;
	}
	
	// ------------------------------------------------------------------------

	/**
	 * Отображение информационного сообщения
	*/ 
	function _show_message($message = FALSE, $link = FALSE, $link_text = FALSE)
	{
		
		if (!$message) {
			$message = lang('error');
		}
		
		if (!$link) {
			$link = 'javascript:history.back()';
		}
		
		if (!$link_text) {
			$link_text = lang('back');
		}

		$local_tpl_data['message'] = $message;
		$local_tpl_data['link'] = $link;
		$local_tpl_data['back_link_txt'] = $link_text;
		$this->tpl_data['content'] = $this->parser->parse('info.html', $local_tpl_data, true);
		$this->parser->parse('main.html', $this->tpl_data);
	}
	
	// ------------------------------------------------------------------------
    
    /**
     * Главная страница со списком баз subnetban
    */
    public function index()
    {
		//~ echo long2ip(1587478527);
		$local_tpl_data['sbdb_list'] 	= $this->_tpl_db_list();
		$this->tpl_data['content'] 		= $this->parser->parse('db_list.html', $local_tpl_data, true);
		
		$this->parser->parse('main.html', $this->tpl_data);
	}
	
	// ------------------------------------------------------------------------
	
    /**
     * Новая база subnetban
    */
    public function add_db()
    {
		$this->load->library('form_validation');
		
		$local_tpl_data = array();
		
		/* Правила */
		$this->form_validation->set_rules('name', lang('name'), 'trim|required|xss_clean');
        $this->form_validation->set_rules('hostname', lang('host'), 'trim|required|xss_clean');
		$this->form_validation->set_rules('username', 'Имя пользователя', 'trim|required|xss_clean');
		$this->form_validation->set_rules('password', lang('password'), 'trim|xss_clean');
		$this->form_validation->set_rules('database', 'База данных', 'trim|required|xss_clean');
		$this->form_validation->set_rules('dbdriver', 'Драйвер базы данных', 'trim|xss_clean');
		//~ $this->form_validation->set_rules('dbprefix', 'Префикс', 'trim|xss_clean');
		$this->form_validation->set_rules('table_name', 'Имя таблицы', 'trim|required|xss_clean');
		
		if ($this->form_validation->run() == false) {
			$this->tpl_data['content'] = $this->parser->parse('add_db.html', $local_tpl_data, true);
		} else {
			$db_cfg['hostname'] = $this->input->post('hostname');
			$db_cfg['username'] = $this->input->post('username');
			$db_cfg['password'] = $this->input->post('password');
			$db_cfg['database'] = $this->input->post('database');
			$db_cfg['dbdriver'] = $this->input->post('dbdriver');
			//~ $db_cfg['dbprefix'] = $this->input->post('dbprefix');
			$db_cfg['table_name'] = $this->input->post('table_name');
			
			$db_cfg['db_debug'] = true;
			
			if (!$db_cfg['dbdriver']) {
				$db_cfg['dbdriver'] = 'mysqli';
			}
			
			if ($error = $this->_found_db_errors($db_cfg)) {
				$this->_show_message($error);
				return false;
			}

			$sql_data['name'] 		= $this->input->post('name');
			$sql_data['hostname'] 	= $db_cfg['hostname'];
			$sql_data['username'] 	= $db_cfg['username'];
			$sql_data['password'] 	= $db_cfg['password'];
			$sql_data['database'] 	= $db_cfg['database'];
			$sql_data['dbdriver'] 	= $db_cfg['dbdriver'];
			//~ $sql_data['dbprefix'] 	= $db_cfg['dbprefix'];
			$sql_data['table_name'] = $db_cfg['table_name'];

			if ($this->sbdb->add_db($sql_data)) {
				$this->_show_message('База данных успешно добавлена', site_url('subnetban'), lang('next'));
				return true;
			} else {
				/* Шансы появления этой ошибки 0.01% */
				$this->_show_message('Ошибка создания базы данных');
				return false;
			}
		}
		
		
		$this->parser->parse('main.html', $this->tpl_data);
	}
	
	// ------------------------------------------------------------------------
    
    /**
     * Редактирование существующей базы данных subnetban
     * 
     * @param int 	идентификатор базы данных subnetban
    */
    public function edit_db($sbdb_id = false)
    {
		if (!$sbdb_id) {
			redirect('subnetban');
		}
		
		$this->load->library('form_validation');
		
		$local_tpl_data = array();
		$local_tpl_data['db_id'] 	= $sbdb_id;
		$local_tpl_data['sbdb_id'] 	= $sbdb_id;
		
		if (!$this->sbdb->select_db($sbdb_id)) {
			$this->_show_message('База выбрана неправильно', site_url('subnetban'));
			return false;
		}
		
		/* Правила */
		$this->form_validation->set_rules('name', lang('name'), 'trim|required|xss_clean');
        $this->form_validation->set_rules('hostname', lang('host'), 'trim|required|xss_clean');
		$this->form_validation->set_rules('username', 'Имя пользователя', 'trim|required|xss_clean');
		$this->form_validation->set_rules('password', lang('password'), 'trim|xss_clean');
		$this->form_validation->set_rules('database', 'База данных', 'trim|required|xss_clean');
		$this->form_validation->set_rules('dbdriver', 'Драйвер базы данных', 'trim|xss_clean');
		//~ $this->form_validation->set_rules('dbprefix', 'Префикс', 'trim|xss_clean');
		$this->form_validation->set_rules('table_name', 'Имя таблицы', 'trim|required|xss_clean');
		
		if ($this->form_validation->run() == false) {
			$local_tpl_data 			+= $this->sbdb->get_sbdb();
			$local_tpl_data['password']	= '***';
			$this->tpl_data['content'] 	= $this->parser->parse('edit_db.html', $local_tpl_data, true);
		} else {
			$db_cfg['hostname'] = $this->input->post('hostname');
			$db_cfg['username'] = $this->input->post('username');
			$db_cfg['password'] = $this->input->post('password');
			$db_cfg['database'] = $this->input->post('database');
			$db_cfg['dbdriver'] = $this->input->post('dbdriver');
			//~ $db_cfg['dbprefix'] = $this->input->post('dbprefix');
			$db_cfg['table_name'] = $this->input->post('table_name');
			
			$db_cfg['db_debug'] = true;
			
			if (!$db_cfg['dbdriver']) {
				$db_cfg['dbdriver'] = 'mysqli';
			}
			
			/* Если значение поля ***, то пароль не будет меняться */
			if ($db_cfg['password'] == "***") {
				$sbdb 				= $this->sbdb->get_sbdb();
				$db_cfg['password']	= $sbdb['password'];
			}
			
			if ($error = $this->_found_db_errors($db_cfg, true)) {
				$this->_show_message($error);
				return false;
			}

			$sql_data['name'] 		= $this->input->post('name');
			$sql_data['hostname'] 	= $db_cfg['hostname'];
			$sql_data['username'] 	= $db_cfg['username'];
			$sql_data['password'] 	= $db_cfg['password'];
			$sql_data['database'] 	= $db_cfg['database'];
			$sql_data['dbdriver'] 	= $db_cfg['dbdriver'];
			//~ $sql_data['dbprefix'] 	= $db_cfg['dbprefix'];
			$sql_data['table_name'] = $db_cfg['table_name'];

			if ($this->sbdb->update_db($sql_data)) {
				$this->_show_message('База данных успешно сохранена', site_url('subnetban'), lang('next'));
				return true;
			} else {
				/* Шансы появления этой ошибки 0.01% */
				$this->_show_message('Ошибка создания базы данных', site_url('subnetban'), lang('next'));
				return false;
			}
		}
		
		$this->parser->parse('main.html', $this->tpl_data);
	}
	
	// ------------------------------------------------------------------------
    
    /**
     * Просмотр существующей базы, редактирование банов
     * 
     * @param int 	идентификатор базы данных subnetban
    */
    public function view_db($sbdb_id = false)
    {
		if (!$sbdb_id) {
			redirect('subnetban');
		}
		
		$local_tpl_data = array();
		$local_tpl_data['db_id'] 	= $sbdb_id;
		$local_tpl_data['sbdb_id'] 	= $sbdb_id;
		
		if (!$this->sbdb->select_db($sbdb_id)) {
			$this->_show_message('База выбрана неправильно', site_url('subnetban'));
			return false;
		}
		
		$local_tpl_data['ban_list'] = $this->sbdb->get_tpl_bans();
		
		$this->tpl_data['content'] = $this->parser->parse('view_db.html', $local_tpl_data, true);
		$this->parser->parse('main.html', $this->tpl_data);
	}
	
	// ------------------------------------------------------------------------
    
    /**
     * Удаление существующей базы данных subnetban
     * Удаляется только информация о базе данных из модуля, сама же база subnetban,
     * если существует, то и будет существовать дальше.
     * 
     * @param int 	идентификатор базы данных subnetban
    */
	public function delete_db($sbdb_id = false, $confirm = '')
    {
		if (!$sbdb_id) {
			redirect('subnetban');
		}
		
		if (!$this->sbdb->select_db($sbdb_id)) {
			$this->_show_message('База выбрана неправильно', site_url('subnetban'));
			return false;
		}
		
		$local_tpl_data = array();
		$local_tpl_data['db_id'] 	= $sbdb_id;
		$local_tpl_data['sbdb_id'] 	= $sbdb_id;
		
		if ($confirm == $this->security->get_csrf_hash()) {
			$this->sbdb->delete_db();
			$this->_show_message('База удалена.', site_url('subnetban') ,lang('next'));
			return true;
		} else {
			/* Пользователь не подтвердил намерения */
			$confirm_tpl['message'] = 'Удалить SB базу? Удаляются лишь сведения о базе, сама база и существующие баны останутся.';
			$confirm_tpl['confirmed_url'] = site_url('subnetban/delete_db/' . $sbdb_id . '/' . $this->security->get_csrf_hash());
			$this->tpl_data['content'] .= $this->parser->parse('confirm.html', $confirm_tpl, true);
		}
		
		$this->parser->parse('main.html', $this->tpl_data);
	}
	
	// ------------------------------------------------------------------------
	
    /**
     * Новый бан
     * 
     * @param int 	$sbdb_id идентификатор базы данных, если не указан, то
     * 				пользователю должно быть предложено выбрать базы в 
     * 				которые нужно добавить бан
    */
    public function add_ban($sbdb_id = false)
    {
		$this->load->library('form_validation');
		$this->load->helper('form');
		
		$local_tpl_data = array();
		$local_tpl_data['db_id'] 	= $sbdb_id;
		$local_tpl_data['sbdb_id'] 	= $sbdb_id;
		
		$this->form_validation->set_rules('startip', 'Start IP', 'trim|required|xss_clean');
		$this->form_validation->set_rules('endip', 'End IP', 'trim|xss_clean');
		$this->form_validation->set_rules('reason', 'Причина', 'trim|required|xss_clean');
		$this->form_validation->set_rules('sbdb[]', 'Базы данных', 'trim|required|xss_clean');
		
		if ($this->form_validation->run() == false) {
			$sb_db_list = $this->sbdb->get_db_list();
		
			if (empty($sb_db_list)) {
				$this->_show_message('Добавьте subnetbans базы');
				return false;
			}
			
			$i = 0;
			foreach ($sb_db_list as &$db) {
				$local_tpl_data['sbdb_list'][$i]['sbdb_name'] 	= $db['name'];
				$local_tpl_data['sbdb_list'][$i]['sbdb_host'] 	= $db['hostname'];
				$local_tpl_data['sbdb_list'][$i]['sbdb_id'] 	= $db['id'];
				
				$local_tpl_data['sbdb_list'][$i]['checkbox_sbdb'] = ($db['id'] == $sbdb_id)
															? form_checkbox("sbdb[{$db['id']}]", 'accept', true)
															: form_checkbox("sbdb[{$db['id']}]", 'accept');
				
				$i ++;
			}
			
			$this->tpl_data['content'] = $this->parser->parse('add_ban.html', $local_tpl_data, true);
		} else {
			$post['startip']			= $this->input->post('startip');
			$post['endip']				= $this->input->post('endip');
			$post['reason']				= $this->input->post('reason');
			
			// Базы данных subnetbans в которые будет добавлена запись
			$sbdb_list					= $this->input->post('sbdb');
			
			// Обработка IP. Преобразование cidr в range ip, если требуется
			if (!$post['endip']) {
				$range_ip = $this->_cidr2range($post['startip']);
				
				$post['startip'] 	= $range_ip[0];
				$post['endip'] 		= $range_ip[1];
			}
			
			if (!filter_var($post['startip'], FILTER_VALIDATE_IP) OR !filter_var($post['endip'], FILTER_VALIDATE_IP)) {
				$this->_show_message('Диапазон IP указан неверно');
				return false;
			}
			
			$post['unknown'] 			= (int)(bool) $this->input->post('unknown');
			$post['native_steam'] 		= (int)(bool) $this->input->post('native_steam');
			$post['steamemu'] 			= (int)(bool) $this->input->post('steamemu');
			$post['rewemu'] 			= (int)(bool) $this->input->post('rewemu');
			$post['old_rewemu'] 		= (int)(bool) $this->input->post('old_rewemu');
			$post['hltv'] 				= (int)(bool) $this->input->post('hltv');
			$post['steamclient2009'] 	= (int)(bool) $this->input->post('steamclient2009');
			$post['avsmp'] 				= (int)(bool) $this->input->post('avsmp');
			$post['rewemu2013'] 		= (int)(bool) $this->input->post('rewemu2013');
			
			foreach($sbdb_list as $key => $value) {
				if ($this->sbdb->select_db($key)) {
					$this->sbdb->insert($post);
					
					/* Засыпаем на 1 секунду, т.к. в качестве
					 * id бана используется время добавления (по другому никак, подстраиваемся под amxx плагин).
					 * А в случае с одинаковым временем возникнут проблемки. */
					sleep(1);
				}
			}
			
			$this->_show_message('Подсеть добавлена', site_url('subnetban/view_db/' . $sbdb_id));
			return true;
		}
		
		$this->parser->parse('main.html', $this->tpl_data);
	}
	
	// ------------------------------------------------------------------------
    
    /**
     * Редактирование бана
     * 
     * @param int 	идентификатор базы данных subnetban
     * @param int 	идентификатор бана в базе данных
    */
    public function edit_ban($sbdb_id = false, $ban_id = false)
    {
		$this->load->library('form_validation');
		$this->load->helper('form');
		
		if (!$sbdb_id or !$ban_id) {
			redirect('subnetban');
		}
		
		$local_tpl_data = array();
		$local_tpl_data['db_id'] 	= $sbdb_id;
		$local_tpl_data['sbdb_id'] 	= $sbdb_id;
		$local_tpl_data['ban_id'] 	= $ban_id;
		
		if (!$this->sbdb->select_db($sbdb_id)) {
			$this->_show_message('База выбрана неправильно', site_url('subnetban'));
			return false;
		}
		
		if (!$ban_data = $this->sbdb->get_ban($ban_id)) {
			$this->_show_message('ID бана указан неверно', site_url('subnetban/view_db/' . $sbdb_id));
			return false;
		}
		
		$this->form_validation->set_rules('startip', 'Start IP', 'trim|required|xss_clean');
		$this->form_validation->set_rules('endip', 'End IP', 'trim|xss_clean');
		$this->form_validation->set_rules('reason', 'Причина', 'trim|required|xss_clean');
		
		if ($this->form_validation->run() == false) {
			$local_tpl_data += $ban_data;
			unset($local_tpl_data['allowedclients']);
			
			$local_tpl_data['checkbox_unknown'] 		= form_checkbox('unknown', 'accept', $ban_data['allowedclients']['unknown']);
			$local_tpl_data['checkbox_native_steam'] 	= form_checkbox('native_steam', 'accept', $ban_data['allowedclients']['native_steam']);
			$local_tpl_data['checkbox_steamemu'] 		= form_checkbox('steamemu', 'accept', $ban_data['allowedclients']['steamemu']);
			$local_tpl_data['checkbox_rewemu'] 			= form_checkbox('rewemu', 'accept', $ban_data['allowedclients']['rewemu']);
			$local_tpl_data['checkbox_old_rewemu'] 		= form_checkbox('old_rewemu', 'accept', $ban_data['allowedclients']['old_rewemu']);
			$local_tpl_data['checkbox_hltv'] 			= form_checkbox('hltv', 'accept', $ban_data['allowedclients']['hltv']);
			$local_tpl_data['checkbox_steamclient2009'] = form_checkbox('steamclient2009', 'accept', $ban_data['allowedclients']['steamclient2009']);
			$local_tpl_data['checkbox_avsmp'] 			= form_checkbox('avsmp', 'accept', $ban_data['allowedclients']['avsmp']);
			$local_tpl_data['checkbox_rewemu2013'] 		= form_checkbox('rewemu2013', 'accept', $ban_data['allowedclients']['rewemu2013']);
			
			$this->tpl_data['content'] = $this->parser->parse('edit_ban.html', $local_tpl_data, true);
		} else {
			
			$post['startip']			= $this->input->post('startip');
			$post['endip']				= $this->input->post('endip');
			$post['reason']				= $this->input->post('reason');
			
			// Обработка IP. Преобразование cidr в range ip, если требуется
			if (!$post['endip']) {
				$range_ip = $this->_cidr2range($post['startip']);
				
				$post['startip'] 	= $range_ip[0];
				$post['endip'] 		= $range_ip[1];
			}
			
			if (!filter_var($post['startip'], FILTER_VALIDATE_IP) OR !filter_var($post['endip'], FILTER_VALIDATE_IP)) {
				$this->_show_message('Диапазон IP указан неверно');
				return false;
			}

			$post['unknown'] 			= (int)(bool) $this->input->post('unknown');
			$post['native_steam'] 		= (int)(bool) $this->input->post('native_steam');
			$post['steamemu'] 			= (int)(bool) $this->input->post('steamemu');
			$post['rewemu'] 			= (int)(bool) $this->input->post('rewemu');
			$post['old_rewemu'] 		= (int)(bool) $this->input->post('old_rewemu');
			$post['hltv'] 				= (int)(bool) $this->input->post('hltv');
			$post['steamclient2009'] 	= (int)(bool) $this->input->post('steamclient2009');
			$post['avsmp'] 				= (int)(bool) $this->input->post('avsmp');
			$post['rewemu2013'] 		= (int)(bool) $this->input->post('rewemu2013');
			
			if ($this->sbdb->update($ban_id, $post)) {
				$this->_show_message('Подсеть сохранена', site_url('subnetban/view_db/' . $sbdb_id));
				return true;
			} else {
				$this->_show_message('Ошибка сохранения подсети', site_url('subnetban/view_db/' . $sbdb_id));
				return false;
			}
		}

		$this->parser->parse('main.html', $this->tpl_data);
	}
	
	// ------------------------------------------------------------------------
    
    /**
     * Удаление бана
     * 
     * @param int 	идентификатор базы данных subnetban
     * @param int 	идентификатор бана в базе данных
    */
	public function delete_ban($sbdb_id = false, $ban_id = false, $confirm = '')
    {
		if (!$sbdb_id or !$ban_id) {
			redirect('subnetban');
		}
		
		if (!$this->sbdb->select_db($sbdb_id)) {
			$this->_show_message('База выбрана неправильно', site_url('subnetban'));
			return false;
		}
		
		if (!$ban_data = $this->sbdb->get_ban($ban_id)) {
			$this->_show_message('ID бана указан неверно', site_url('subnetban/view_db/' . $sbdb_id));
			return false;
		}
		
		$local_tpl_data = array();
		
		if ($confirm == $this->security->get_csrf_hash()) {
			$this->sbdb->delete($ban_id);
			$this->_show_message('Бан подсети успешно удален.', site_url('subnetban/view_db/' . $sbdb_id) ,lang('next'));
			return true;
		} else {
			/* Пользователь не подтвердил намерения */
			$confirm_tpl['message'] = 'Удалить бан подсети?';
			$confirm_tpl['confirmed_url'] = site_url('subnetban/delete_ban/' . $sbdb_id . '/' . $ban_id .  '/' . $this->security->get_csrf_hash());
			$this->tpl_data['content'] .= $this->parser->parse('confirm.html', $confirm_tpl, true);
		}

		$this->parser->parse('main.html', $this->tpl_data);
	}
}
